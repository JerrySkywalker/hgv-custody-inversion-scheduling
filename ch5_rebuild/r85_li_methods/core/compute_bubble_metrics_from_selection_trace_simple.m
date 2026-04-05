function out = compute_bubble_metrics_from_selection_trace_simple(ch5case, selection_trace, tag)
%COMPUTE_BUBBLE_METRICS_FROM_SELECTION_TRACE_SIMPLE
% Lightweight compare chain for R8.5d.1:
%   - no replay RMSE
%   - compare bubble / switch / resource metrics only
%
% Inputs:
%   ch5case
%   selection_trace{k}.best_pair
%
% Outputs:
%   bubble_steps
%   bubble_time_s
%   switch_count
%   resource_score
%   mean_MG_proxy

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');

[x_truth, sat_pos, dt, gamma_req] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);

assert(numel(selection_trace) == n_steps, 'selection_trace length mismatch.');

Cr = build_requirement_projection_Cr(6, 'position');

bubble_mask = false(n_steps,1);
MG_proxy = NaN(n_steps,1);
switch_count = 0;
prev_pair = [];

for k = 1:n_steps
    rec = selection_trace{k};
    if ~isstruct(rec) || ~isfield(rec, 'best_pair') || isempty(rec.best_pair)
        bubble_mask(k) = true;
        continue;
    end

    pair = rec.best_pair(:).';
    if numel(pair) ~= 2
        bubble_mask(k) = true;
        continue;
    end

    if ~isempty(prev_pair)
        if any(pair ~= prev_pair)
            switch_count = switch_count + 1;
        end
    end
    prev_pair = pair;

    J_pair = local_build_J_pair_from_geometry( ...
        sat_pos(k,:,pair(1)), sat_pos(k,:,pair(2)), x_truth(k,1:3));

    P_minus = inv(J_pair + 1e-9 * eye(3));
    P_minus = 0.5 * (P_minus + P_minus.');

    MG_proxy(k) = 1 / max(eig(P_minus));
    bubble_mask(k) = (MG_proxy(k) < gamma_req);
end

bubble_steps = sum(bubble_mask);
bubble_time_s = bubble_steps * dt;
resource_score = 2;

summary = struct();
summary.tag = string(tag);
summary.n_steps = n_steps;
summary.bubble_steps = bubble_steps;
summary.bubble_time_s = bubble_time_s;
summary.switch_count = switch_count;
summary.resource_score = resource_score;
summary.mean_MG_proxy = mean(MG_proxy(~isnan(MG_proxy)), 'omitnan');

out = struct();
out.summary = summary;
out.bubble_mask = bubble_mask;
out.MG_proxy = MG_proxy;
out.selection_trace = selection_trace;
end

function [x_truth, sat_pos, dt, gamma_req] = local_resolve_case_data(ch5case)
assert(isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X'), 'truth.X missing.');
assert(isfield(ch5case, 'satbank') && isfield(ch5case.satbank, 'r_eci_km'), 'satbank.r_eci_km missing.');
assert(isfield(ch5case, 'dt'), 'dt missing.');
assert(isfield(ch5case, 'gamma_req'), 'gamma_req missing.');

x_truth = ch5case.truth.X(:,1:6);
sat_pos = ch5case.satbank.r_eci_km;
if ndims(sat_pos) == 3 && size(sat_pos,2) == 3
    % already [Nt x 3 x Ns]
elseif ndims(sat_pos) == 3 && size(sat_pos,1) == 3
    sat_pos = permute(sat_pos, [2 1 3]);
elseif ndims(sat_pos) == 3 && size(sat_pos,3) == 3
    sat_pos = permute(sat_pos, [1 3 2]);
else
    error('Unexpected satbank.r_eci_km shape.');
end

dt = ch5case.dt;
gamma_req = ch5case.gamma_req;
end

function J_pair = local_build_J_pair_from_geometry(rs1, rs2, rt)
u1 = (rt(:)-rs1(:)); u1 = u1 / norm(u1);
u2 = (rt(:)-rs2(:)); u2 = u2 / norm(u2);

H1 = [eye(3) - u1*u1.', zeros(3,3)];
H2 = [eye(3) - u2*u2.', zeros(3,3)];
R = 1e-4 * eye(3);

J = H1.'*(R\H1) + H2.'*(R\H2);
J_pair = J(1:3,1:3);
J_pair = 0.5 * (J_pair + J_pair.');
end
