function out = compute_formal_bubble_metrics_from_selection_trace(ch5case, selection_trace, tag)
%COMPUTE_FORMAL_BUBBLE_METRICS_FROM_SELECTION_TRACE
% R8.5d.2 formal compare chain:
%   - build J_pair(k) from actual geometry
%   - aggregate finite-window information Y_W(k)
%   - bubble judged by lambda_min(Y_W(k)) < gamma_req

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');

[x_truth, sat_pos, dt, gamma_req, W] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);
assert(numel(selection_trace) == n_steps, 'selection_trace length mismatch.');

J_seq = zeros(3,3,n_steps);
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

    J_seq(:,:,k) = local_build_J_pair_from_geometry( ...
        sat_pos(k,:,pair(1)), sat_pos(k,:,pair(2)), x_truth(k,1:3));
end

n_win = n_steps;
lambda_min_window = NaN(n_win,1);
bubble_mask = false(n_win,1);
bubble_depth = zeros(n_win,1);

for k = 1:n_win
    k2 = min(n_steps, k + W - 1);
    YW = zeros(3,3);
    for t = k:k2
        YW = YW + J_seq(:,:,t);
    end
    YW = 0.5 * (YW + YW.');
    lam = eig(YW);
    lam = real(lam);
    lam_min = min(lam);
    lambda_min_window(k) = lam_min;
    bubble_mask(k) = (lam_min < gamma_req);
    bubble_depth(k) = max(gamma_req - lam_min, 0);
end

bubble_steps = sum(bubble_mask);
bubble_time_s = bubble_steps * dt;
max_bubble_depth = max(bubble_depth);
mean_lambda_min_window = mean(lambda_min_window, 'omitnan');
resource_score = 2;

summary = struct();
summary.tag = string(tag);
summary.n_steps = n_steps;
summary.window_length_steps = W;
summary.gamma_req = gamma_req;
summary.bubble_steps = bubble_steps;
summary.bubble_time_s = bubble_time_s;
summary.max_bubble_depth = max_bubble_depth;
summary.mean_lambda_min_window = mean_lambda_min_window;
summary.switch_count = switch_count;
summary.resource_score = resource_score;
summary.n_missing_pair_steps = sum(~has_pair_mask);

out = struct();
out.summary = summary;
out.J_seq = J_seq;
out.lambda_min_window = lambda_min_window;
out.bubble_mask = bubble_mask;
out.bubble_depth = bubble_depth;
out.selection_trace = selection_trace;
end

function [x_truth, sat_pos, dt, gamma_req, W] = local_resolve_case_data(ch5case)
assert(isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X'), 'truth.X missing.');
assert(isfield(ch5case, 'satbank') && isfield(ch5case.satbank, 'r_eci_km'), 'satbank.r_eci_km missing.');
assert(isfield(ch5case, 'dt'), 'dt missing.');
assert(isfield(ch5case, 'gamma_req'), 'gamma_req missing.');

x_truth = ch5case.truth.X(:,1:6);
sat_pos = ch5case.satbank.r_eci_km;

if ndims(sat_pos) == 3 && size(sat_pos,2) == 3
    % [Nt x 3 x Ns]
elseif ndims(sat_pos) == 3 && size(sat_pos,1) == 3
    sat_pos = permute(sat_pos, [2 1 3]);
elseif ndims(sat_pos) == 3 && size(sat_pos,3) == 3
    sat_pos = permute(sat_pos, [1 3 2]);
else
    error('Unexpected satbank.r_eci_km shape.');
end

dt = ch5case.dt;
gamma_req = ch5case.gamma_req;

if isfield(ch5case, 'window') && isfield(ch5case.window, 'length_steps')
    W = ch5case.window.length_steps;
else
    error('ch5case.window.length_steps missing.');
end
end

function J_pair = local_build_J_pair_from_geometry(rs1, rs2, rt)
u1 = (rt(:)-rs1(:)); u1 = u1 / norm(u1);
u2 = (rt(:)-rs2(:)); u2 = u2 / norm(u2);

H1 = eye(3) - u1*u1.';
H2 = eye(3) - u2*u2.';

R = 1e-4 * eye(3);
J_pair = H1.'*(R\H1) + H2.'*(R\H2);
J_pair = 0.5 * (J_pair + J_pair.');
end
