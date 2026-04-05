function candidates = build_r85_pair_candidates_from_case(li_case, step_index)
%BUILD_R85_PAIR_CANDIDATES_FROM_CASE
% R8.5c.4:
%   Build candidate pairs by directly reusing ch5case.candidates.pair_bank{step_index}.
%
% This aligns R8.5 with the native ch5r candidate-layer semantics.

assert(isstruct(li_case), 'li_case must be a struct.');
assert(isfield(li_case, 'base_case'), 'li_case.base_case missing.');
assert(isnumeric(step_index) && isscalar(step_index), 'step_index must be scalar.');

base_case = li_case.base_case;
assert(isfield(base_case, 'candidates') && isfield(base_case.candidates, 'pair_bank'), ...
    'base_case.candidates.pair_bank is required for R8.5c.4 alignment.');

pair_bank = base_case.candidates.pair_bank;
assert(step_index >= 1 && step_index <= numel(pair_bank), 'step_index out of range.');

pairs = pair_bank{step_index};
if isempty(pairs)
    candidates = struct('sat_pair', {}, 'pta_len_s', {}, 'cn_value', {}, ...
        'detY_rim_value', {}, 'detY_fast_value', {}, ...
        'candidate_source', {}, 'sat_field_path', {}, 'tgt_field_path', {});
    return;
end

[sat_pos, sat_field_path] = local_resolve_sat_positions(base_case);
[tgt_pos, tgt_field_path] = local_resolve_target_positions(base_case);

n_pair = size(pairs, 1);
candidates = repmat(struct( ...
    'sat_pair', [], ...
    'pta_len_s', NaN, ...
    'cn_value', NaN, ...
    'detY_rim_value', NaN, ...
    'detY_fast_value', NaN, ...
    'candidate_source', "", ...
    'sat_field_path', "", ...
    'tgt_field_path', ""), n_pair, 1);

win_steps = li_case.resource.interval_steps;
k2 = min(size(tgt_pos,1), step_index + win_steps - 1);

for i = 1:n_pair
    pair = pairs(i,:);
    s1 = pair(1);
    s2 = pair(2);

    pta_pair = local_pair_visible_duration_from_pair_bank(pair_bank, pair, step_index, k2) * li_case.meta.dt;
    [geom_score, cn_proxy] = local_pair_geometry_proxy( ...
        sat_pos(step_index,:,s1), sat_pos(step_index,:,s2), tgt_pos(step_index,:));

    candidates(i).sat_pair = pair;
    candidates(i).pta_len_s = pta_pair;
    candidates(i).cn_value = cn_proxy;
    candidates(i).detY_rim_value = geom_score;
    candidates(i).detY_fast_value = 0.95 * geom_score;
    candidates(i).candidate_source = "ch5case.candidates.pair_bank";
    candidates(i).sat_field_path = string(sat_field_path);
    candidates(i).tgt_field_path = string(tgt_field_path);
end
end

function dur_steps = local_pair_visible_duration_from_pair_bank(pair_bank, pair, k1, k2)
dur_steps = 0;
pair_sorted = sort(pair(:)).';

for k = k1:k2
    pairs_k = pair_bank{k};
    if isempty(pairs_k)
        continue;
    end
    pairs_k = sort(pairs_k, 2);
    hit = any(all(pairs_k == pair_sorted, 2));
    if hit
        dur_steps = dur_steps + 1;
    end
end
end

function [sat_pos, field_path] = local_resolve_sat_positions(base_case)
field_path = "satbank.r_eci_km";
assert(isfield(base_case, 'satbank') && isfield(base_case.satbank, 'r_eci_km'), ...
    'base_case.satbank.r_eci_km is required.');

val = base_case.satbank.r_eci_km;
sz = size(val);

if ndims(val) == 3 && sz(2) == 3
    sat_pos = val;
elseif ndims(val) == 3 && sz(1) == 3
    sat_pos = permute(val, [2 1 3]);
elseif ndims(val) == 3 && sz(3) == 3
    sat_pos = permute(val, [1 3 2]);
else
    error('Unrecognized satbank.r_eci_km shape.');
end
end

function [tgt_pos, field_path] = local_resolve_target_positions(base_case)
field_path = "truth.r_eci_km";

if isfield(base_case, 'truth') && isfield(base_case.truth, 'r_eci_km')
    val = base_case.truth.r_eci_km;
elseif isfield(base_case, 'truth') && isfield(base_case.truth, 'X')
    field_path = "truth.X";
    val = base_case.truth.X(:,1:3);
else
    error('base_case.truth.r_eci_km or truth.X is required.');
end

sz = size(val);
if ismatrix(val) && sz(2) >= 3
    tgt_pos = val(:,1:3);
elseif ismatrix(val) && sz(1) >= 3
    tgt_pos = val(1:3,:).';
else
    error('Unrecognized truth position array shape.');
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
