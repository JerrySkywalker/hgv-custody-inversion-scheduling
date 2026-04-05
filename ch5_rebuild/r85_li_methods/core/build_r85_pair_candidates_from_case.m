function candidates = build_r85_pair_candidates_from_case(li_case, step_index)
%BUILD_R85_PAIR_CANDIDATES_FROM_CASE
% Build 2-satellite pair candidates from current ch5r case at a given step.
%
% This is R8.5c.2 real-candidate bridge:
%   1) collect visible satellites at step_index
%   2) enumerate 2-satellite pairs
%   3) attach placeholder/bridge metrics for Li-style criteria
%
% Current version:
%   - PTA uses visible-duration proxy inside local window
%   - CN / detY_rim / detY_fast use geometry-based bridge surrogates
%   - next step will replace surrogates with full Li formulas

assert(isstruct(li_case), 'li_case must be a struct.');
assert(isfield(li_case, 'base_case'), 'li_case.base_case missing.');
assert(isnumeric(step_index) && isscalar(step_index), 'step_index must be scalar.');

base_case = li_case.base_case;

sat_pos = local_resolve_sat_positions(base_case);
tgt_pos = local_resolve_target_positions(base_case);
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
    candidates = struct('sat_pair', {}, 'pta_len_s', {}, 'cn_value', {}, 'detY_rim_value', {}, 'detY_fast_value', {});
    return;
end

pairs = nchoosek(vis_idx, 2);
n_pair = size(pairs,1);

candidates = repmat(struct( ...
    'sat_pair', [], ...
    'pta_len_s', NaN, ...
    'cn_value', NaN, ...
    'detY_rim_value', NaN, ...
    'detY_fast_value', NaN), n_pair, 1);

win_steps = li_case.resource.interval_steps;
k2 = min(size(tgt_pos,1), step_index + win_steps - 1);

for i = 1:n_pair
    pair = pairs(i,:);
    s1 = pair(1);
    s2 = pair(2);

    pta1 = local_visible_count_over_window(sat_pos(:,:,s1), tgt_pos, step_index, k2, li_case.sensor.max_range_km, li_case.sensor.off_nadir_deg);
    pta2 = local_visible_count_over_window(sat_pos(:,:,s2), tgt_pos, step_index, k2, li_case.sensor.max_range_km, li_case.sensor.off_nadir_deg);
    pta_pair = min(pta1, pta2) * li_case.meta.dt;

    [geom_score, cn_proxy] = local_pair_geometry_proxy(sat_pos(step_index,:,s1), sat_pos(step_index,:,s2), tgt_pos(step_index,:));

    candidates(i).sat_pair = pair;
    candidates(i).pta_len_s = pta_pair;
    candidates(i).cn_value = cn_proxy;
    candidates(i).detY_rim_value = geom_score;
    candidates(i).detY_fast_value = 0.95 * geom_score;
end
end

function sat_pos = local_resolve_sat_positions(base_case)
if isfield(base_case, 'satellites') && isfield(base_case.satellites, 'r_eci_km')
    sat_pos = base_case.satellites.r_eci_km;
    return;
end
if isfield(base_case, 'constellation') && isfield(base_case.constellation, 'r_eci_km')
    sat_pos = base_case.constellation.r_eci_km;
    return;
end
error('Satellite position array not found in base_case.');
end

function tgt_pos = local_resolve_target_positions(base_case)
if isfield(base_case, 'truth') && isfield(base_case.truth, 'r_eci_km')
    tgt_pos = base_case.truth.r_eci_km;
    return;
end
if isfield(base_case, 'target_truth') && isfield(base_case.target_truth, 'r_eci_km')
    tgt_pos = base_case.target_truth.r_eci_km;
    return;
end
if isfield(base_case, 'target_case') && isfield(base_case.target_case, 'r_eci_km')
    tgt_pos = base_case.target_case.r_eci_km;
    return;
end
error('Target truth position array not found in base_case.');
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
