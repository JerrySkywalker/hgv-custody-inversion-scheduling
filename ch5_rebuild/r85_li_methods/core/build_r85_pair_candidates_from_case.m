function candidates = build_r85_pair_candidates_from_case(li_case, step_index)
%BUILD_R85_PAIR_CANDIDATES_FROM_CASE
% Build 2-satellite pair candidates from current ch5r case at a given step.
%
% R8.5c.2 fixed version:
%   - robust field resolution for satellite/target positions
%   - prefer explicit fields
%   - then fallback to recursive heuristic search

assert(isstruct(li_case), 'li_case must be a struct.');
assert(isfield(li_case, 'base_case'), 'li_case.base_case missing.');
assert(isnumeric(step_index) && isscalar(step_index), 'step_index must be scalar.');

base_case = li_case.base_case;

[sat_pos, sat_field_path] = local_resolve_sat_positions(base_case);
[tgt_pos, tgt_field_path] = local_resolve_target_positions(base_case);

assert(step_index >= 1 && step_index <= size(tgt_pos,1), 'step_index out of range.');

n_sat = size(sat_pos, 3);
vis_idx = [];

for s = 1:n_sat
    rs = sat_pos(step_index,:,s);
    rt = tgt_pos(step_index,:);
    los = rt - rs;
    rho = norm(los);

    if rho > li_case.sensor.max_range_km
        continue;
    end

    if ~local_pass_off_nadir(rs, rt, li_case.sensor.off_nadir_deg)
        continue;
    end

    vis_idx(end+1) = s; %#ok<AGROW>
end

if numel(vis_idx) < 2
    candidates = struct('sat_pair', {}, 'pta_len_s', {}, 'cn_value', {}, ...
        'detY_rim_value', {}, 'detY_fast_value', {}, ...
        'sat_field_path', {}, 'tgt_field_path', {});
    return;
end

pairs = nchoosek(vis_idx, 2);
n_pair = size(pairs,1);

candidates = repmat(struct( ...
    'sat_pair', [], ...
    'pta_len_s', NaN, ...
    'cn_value', NaN, ...
    'detY_rim_value', NaN, ...
    'detY_fast_value', NaN, ...
    'sat_field_path', "", ...
    'tgt_field_path', ""), n_pair, 1);

win_steps = li_case.resource.interval_steps;
k2 = min(size(tgt_pos,1), step_index + win_steps - 1);

for i = 1:n_pair
    pair = pairs(i,:);
    s1 = pair(1);
    s2 = pair(2);

    pta1 = local_visible_count_over_window(sat_pos(:,:,s1), tgt_pos, step_index, k2, ...
        li_case.sensor.max_range_km, li_case.sensor.off_nadir_deg);
    pta2 = local_visible_count_over_window(sat_pos(:,:,s2), tgt_pos, step_index, k2, ...
        li_case.sensor.max_range_km, li_case.sensor.off_nadir_deg);
    pta_pair = min(pta1, pta2) * li_case.meta.dt;

    [geom_score, cn_proxy] = local_pair_geometry_proxy( ...
        sat_pos(step_index,:,s1), sat_pos(step_index,:,s2), tgt_pos(step_index,:));

    candidates(i).sat_pair = pair;
    candidates(i).pta_len_s = pta_pair;
    candidates(i).cn_value = cn_proxy;
    candidates(i).detY_rim_value = geom_score;
    candidates(i).detY_fast_value = 0.95 * geom_score;
    candidates(i).sat_field_path = string(sat_field_path);
    candidates(i).tgt_field_path = string(tgt_field_path);
end
end

function [sat_pos, field_path] = local_resolve_sat_positions(base_case)
% Return [Nt x 3 x Ns] satellite position array

% 1) explicit likely fields
trial_paths = { ...
    'satbank.r_eci_km', ...
    'satbank.r_eci_all_km', ...
    'satbank.r_eci', ...
    'satellites.r_eci_km', ...
    'constellation.r_eci_km', ...
    'satbank.positions_eci_km', ...
    'satbank.positions_km'};

for i = 1:numel(trial_paths)
    [tf, val] = local_try_get_path(base_case, trial_paths{i});
    if tf
        arr = local_normalize_sat_array(val);
        if ~isempty(arr)
            sat_pos = arr;
            field_path = trial_paths{i};
            return;
        end
    end
end

% 2) recursive search, prefer fields containing sat/satbank/constellation
[hits, paths] = local_recursive_collect_numeric(base_case, "");
best_idx = 0;
for i = 1:numel(hits)
    arr = local_normalize_sat_array(hits{i});
    if ~isempty(arr)
        p = lower(paths{i});
        if contains(p, 'satbank') || contains(p, 'sat') || contains(p, 'constellation')
            sat_pos = arr;
            field_path = paths{i};
            return;
        end
        if best_idx == 0
            best_idx = i;
        end
    end
end

if best_idx ~= 0
    sat_pos = local_normalize_sat_array(hits{best_idx});
    field_path = paths{best_idx};
    return;
end

error('Satellite position array not found in base_case.');
end

function [tgt_pos, field_path] = local_resolve_target_positions(base_case)
% Return [Nt x 3] target truth position array

trial_paths = { ...
    'truth.r_eci_km', ...
    'target_truth.r_eci_km', ...
    'target_case.r_eci_km', ...
    'truth.X', ...
    'truth.x_truth', ...
    'x_truth'};

for i = 1:numel(trial_paths)
    [tf, val] = local_try_get_path(base_case, trial_paths{i});
    if tf
        arr = local_normalize_target_array(val);
        if ~isempty(arr)
            tgt_pos = arr;
            field_path = trial_paths{i};
            return;
        end
    end
end

[hits, paths] = local_recursive_collect_numeric(base_case, "");
best_idx = 0;
for i = 1:numel(hits)
    arr = local_normalize_target_array(hits{i});
    if ~isempty(arr)
        p = lower(paths{i});
        if contains(p, 'truth') || contains(p, 'target')
            tgt_pos = arr;
            field_path = paths{i};
            return;
        end
        if best_idx == 0
            best_idx = i;
        end
    end
end

if best_idx ~= 0
    tgt_pos = local_normalize_target_array(hits{best_idx});
    field_path = paths{best_idx};
    return;
end

error('Target truth position array not found in base_case.');
end

function [tf, val] = local_try_get_path(S, path_str)
parts = strsplit(path_str, '.');
val = S;
tf = true;
for i = 1:numel(parts)
    if isstruct(val) && isfield(val, parts{i})
        val = val.(parts{i});
    else
        tf = false;
        val = [];
        return;
    end
end
end

function arr = local_normalize_sat_array(val)
arr = [];

if ~isnumeric(val) || isempty(val)
    return;
end

sz = size(val);

% [Nt x 3 x Ns]
if ndims(val) == 3 && sz(2) == 3 && sz(1) > 10 && sz(3) > 1
    arr = val;
    return;
end

% [3 x Nt x Ns] -> [Nt x 3 x Ns]
if ndims(val) == 3 && sz(1) == 3 && sz(2) > 10 && sz(3) > 1
    arr = permute(val, [2 1 3]);
    return;
end

% [Nt x Ns x 3] -> [Nt x 3 x Ns]
if ndims(val) == 3 && sz(3) == 3 && sz(1) > 10 && sz(2) > 1
    arr = permute(val, [1 3 2]);
    return;
end
end

function arr = local_normalize_target_array(val)
arr = [];

if ~isnumeric(val) || isempty(val)
    return;
end

sz = size(val);

% [Nt x 3]
if ismatrix(val) && sz(2) >= 3 && sz(1) > 10
    arr = val(:,1:3);
    return;
end

% [3 x Nt] -> [Nt x 3]
if ismatrix(val) && sz(1) >= 3 && sz(2) > 10
    arr = val(1:3,:).';
    return;
end
end

function [vals, paths] = local_recursive_collect_numeric(S, prefix)
vals = {};
paths = {};

if isnumeric(S)
    vals = {S};
    paths = {char(prefix)};
    return;
end

if ~isstruct(S)
    return;
end

fn = fieldnames(S);
for i = 1:numel(fn)
    if strlength(string(prefix)) == 0
        p = string(fn{i});
    else
        p = string(prefix) + "." + string(fn{i});
    end
    [vsub, psub] = local_recursive_collect_numeric(S.(fn{i}), p);
    vals = [vals, vsub]; %#ok<AGROW>
    paths = [paths, psub]; %#ok<AGROW>
end
end

function tf = local_pass_off_nadir(rs, rt, off_nadir_deg)
nadir = -rs(:) / norm(rs);
los = (rt(:) - rs(:));
los = los / norm(los);
ang = acosd(max(-1, min(1, dot(nadir, los))));
tf = (ang <= off_nadir_deg);
end

function cnt = local_visible_count_over_window(sat_track, tgt_pos, k1, k2, max_range_km, off_nadir_deg)
cnt = 0;
for k = k1:k2
    rs = sat_track(k,:);
    rt = tgt_pos(k,:);
    if norm(rt-rs) <= max_range_km && local_pass_off_nadir(rs, rt, off_nadir_deg)
        cnt = cnt + 1;
    end
end
end

function [geom_score, cn_proxy] = local_pair_geometry_proxy(rs1, rs2, rt)
u1 = (rt(:)-rs1(:)); u1 = u1 / norm(u1);
u2 = (rt(:)-rs2(:)); u2 = u2 / norm(u2);

cosang = max(-1, min(1, dot(u1,u2)));
sep = acos(cosang);

geom_score = 1e5 * max(sep, 1e-6);
cn_proxy = 1 / max(sep, 1e-6);
end
