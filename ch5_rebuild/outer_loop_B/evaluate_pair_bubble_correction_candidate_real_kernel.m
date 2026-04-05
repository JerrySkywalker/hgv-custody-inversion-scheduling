function cand = evaluate_pair_bubble_correction_candidate_real_kernel(cfg, ch5case, selection_trace_prefix, pair, k_now)
%EVALUATE_PAIR_BUBBLE_CORRECTION_CANDIDATE_REAL_KERNEL
% R8-C.3 real-kernel-aligned candidate evaluation.
%
% Reuse the same future-window kernel as R5-real:
%   predict_future_window_information(...)
%
% Bubble-correction quantities are built from future lambda_min series:
%   Xi_B  = min(lambda_min_future) - gamma_req
%   tau_B = first future time when lambda_min_future <= gamma_req
%   A_B   = sum [gamma_req - lambda_min_future]_+ * dt

assert(isstruct(cfg), 'cfg must be struct.');
assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace_prefix), 'selection_trace_prefix must be cell.');
assert(isnumeric(pair) && numel(pair) == 2, 'pair must be length-2 numeric vector.');
assert(isnumeric(k_now) && isscalar(k_now) && k_now >= 1, 'k_now invalid.');

horizon_steps = cfg.ch5r.r5.horizon_steps;
pred = predict_future_window_information(ch5case, selection_trace_prefix, pair, k_now, horizon_steps);

lambda_min_future = pred.lambda_min_future(:);
gamma_req = ch5case.gamma_req;
dt = ch5case.dt;

Xi_B = min(lambda_min_future) - gamma_req;
R_B = max(0, -Xi_B);

idx_fail = find(lambda_min_future <= gamma_req, 1, 'first');
if isempty(idx_fail)
    tau_B_idx = inf;
    tau_B_time_s = inf;
    has_failure = false;
else
    tau_B_idx = idx_fail;
    tau_B_time_s = idx_fail * dt;
    has_failure = true;
end

A_B = sum(max(gamma_req - lambda_min_future, 0)) * dt;

switch_cost = 0;
if k_now > 1 && numel(selection_trace_prefix) >= k_now-1 ...
        && isstruct(selection_trace_prefix{k_now-1}) ...
        && isfield(selection_trace_prefix{k_now-1}, 'pair') ...
        && ~isempty(selection_trace_prefix{k_now-1}.pair)
    if ~isequal(selection_trace_prefix{k_now-1}.pair, pair)
        switch_cost = 1;
    end
end

cand = struct();
cand.pair = reshape(pair, 1, 2);
cand.pred = pred;
cand.lambda_min_future = lambda_min_future;
cand.min_future_lambda = pred.min_future_lambda;

cand.Xi_B = Xi_B;
cand.R_B = R_B;
cand.tau_B_idx = tau_B_idx;
cand.tau_B_time_s = tau_B_time_s;
cand.has_failure = has_failure;
cand.A_B = A_B;

cand.switch_cost = switch_cost;
cand.resource_cost = 2;
end
