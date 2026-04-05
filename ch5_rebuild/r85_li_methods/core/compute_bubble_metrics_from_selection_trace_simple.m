function out = compute_bubble_metrics_from_selection_trace_simple(ch5case, selection_trace, tag)
%COMPUTE_BUBBLE_METRICS_FROM_SELECTION_TRACE_SIMPLE
% R8.5d.1a aligned compare chain:
%   - no replay RMSE
%   - bubble judged by relative normalized MG_proxy threshold
%   - current_method trace compatible

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');

[x_truth, sat_pos, dt] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);

assert(numel(selection_trace) == n_steps, 'selection_trace length mismatch.');

MG_proxy = NaN(n_steps,1);
has_pair_mask = false(n_steps,1);
switch_count = 0;
prev_pair = [];

for k = 1:n_steps
    rec = selection_trace{k};
    if ~isstruct(rec) || ~isfield(rec, 'best_pair') || isempty(rec.best_pair)
        continue;
    end

    pair = rec.best_pair(:).';
    if numel(pair) ~= 2 || any(isnan(pair))
        continue;
    end

    has_pair_mask(k) = true;

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
end

valid_vals = MG_proxy(has_pair_mask & isfinite(MG_proxy));
assert(~isempty(valid_vals), 'No valid MG_proxy values could be computed for this selection trace.');

mg_min = min(valid_vals);
mg_max = max(valid_vals);
tau_rel = 0.2;

MG_norm = NaN(n_steps,1);
bubble_mask = false(n_steps,1);

for k = 1:n_steps
    if ~has_pair_mask(k) || ~isfinite(MG_proxy(k))
        bubble_mask(k) = true;
        continue;
    end

    MG_norm(k) = (MG_proxy(k) - mg_min) / (mg_max - mg_min + 1e-12);
    bubble_mask(k) = (MG_norm(k) < tau_rel);
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
summary.mean_MG_proxy = mean(valid_vals, 'omitnan');
summary.min_MG_proxy = mg_min;
summary.max_MG_proxy = mg_max;
summary.mean_MG_norm = mean(MG_norm(has_pair_mask), 'omitnan');
summary.tau_rel = tau_rel;
summary.n_missing_pair_steps = sum(~has_pair_mask);

out = struct();
out.summary = summary;
out.bubble_mask = bubble_mask;
out.MG_proxy = MG_proxy;
out.MG_norm = MG_norm;
out.selection_trace = selection_trace;
end

function [x_truth, sat_pos, dt] = local_resolve_case_data(ch5case)
assert(isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X'), 'truth.X missing.');
assert(isfield(ch5case, 'satbank') && isfield(ch5case.satbank, 'r_eci_km'), 'satbank.r_eci_km missing.');
assert(isfield(ch5case, 'dt'), 'dt missing.');

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
