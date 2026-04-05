function cand = evaluate_pair_bubble_correction_candidate(pred_state, pred_cov, pair_sel, sat_pos, model, Q, H_fun, R_single, Cr, Gamma_req, dt, window_len, prev_pair)
%EVALUATE_PAIR_BUBBLE_CORRECTION_CANDIDATE Evaluate one pair candidate for R8-C.
%
% Inputs:
%   pred_state   : [nx x 1] predicted state at current step
%   pred_cov     : [nx x nx] predicted covariance at current step
%   pair_sel     : [1 x 2] selected satellite indices
%   sat_pos      : [3 x Ns] satellite positions (used as deterministic geometry tags)
%   model        : local DMD model with field A
%   Q            : process covariance
%   H_fun        : measurement Jacobian handle
%   R_single     : single-sensor measurement covariance
%   Cr           : requirement projection matrix
%   Gamma_req    : requirement upper bound
%   dt           : time step
%   window_len   : horizon length
%   prev_pair    : previous selected pair or empty
%
% Outputs:
%   cand : struct with Xi_B, tau_B_time_s, A_B, switch_cost, resource_cost, pair, ...

assert(isnumeric(pred_state) && iscolumn(pred_state), 'pred_state must be column vector.');
assert(isnumeric(pred_cov) && ismatrix(pred_cov), 'pred_cov must be covariance matrix.');
assert(isnumeric(pair_sel) && numel(pair_sel) == 2, 'pair_sel must be length-2 numeric vector.');
assert(isnumeric(sat_pos) && size(sat_pos,1) == 3, 'sat_pos must be [3 x Ns].');
assert(isstruct(model) && isfield(model, 'A'), 'model must contain field A.');
assert(isnumeric(Q) && ismatrix(Q), 'Q must be numeric matrix.');
assert(isa(H_fun, 'function_handle'), 'H_fun must be function handle.');
assert(isnumeric(R_single) && ismatrix(R_single), 'R_single must be covariance matrix.');
assert(isnumeric(Cr) && ismatrix(Cr), 'Cr must be numeric matrix.');
assert(isnumeric(Gamma_req) && isscalar(Gamma_req), 'Gamma_req invalid.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt invalid.');
assert(isnumeric(window_len) && isscalar(window_len) && window_len >= 1, 'window_len invalid.');

nx = numel(pred_state);
x_seq = zeros(nx, window_len);
F_seq = zeros(nx, nx, window_len);
Pplus_seq = zeros(nx, nx, window_len);

x_tmp = pred_state;
P_tmp = pred_cov;

% simple deterministic pair-dependent geometry modulation
pair_center = mean(sat_pos(:, pair_sel), 2);
geom_scale = 1.0 / (1.0 + 1e-4 * norm(pair_center));

for ell = 1:window_len
    x_tmp = propagate_state_koopman_dmd(model, x_tmp);
    x_seq(:, ell) = x_tmp;
    F_seq(:,:,ell) = model.A;

    P_minus_ell = model.A * P_tmp * model.A.' + Q;

    H_base = H_fun(x_tmp);
    H_eff = geom_scale * H_base;
    R_eff = R_single;

    S_ell = H_eff * P_minus_ell * H_eff.' + R_eff;
    K_ell = (P_minus_ell * H_eff.') / S_ell;
    I = eye(nx);
    P_plus_ell = (I - K_ell * H_eff) * P_minus_ell * (I - K_ell * H_eff).' + K_ell * R_eff * K_ell.';
    P_plus_ell = 0.5 * (P_plus_ell + P_plus_ell.');

    Pplus_seq(:,:,ell) = P_plus_ell;
    P_tmp = P_plus_ell;
end

W_cur = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R_single);
MG_cur = compute_structural_metric_MG(W_cur, Cr);

req = compute_requirement_margin_series_forecast(Pplus_seq, Cr, Gamma_req);
bubble = compute_requirement_induced_bubble_margin(req.margin_series);
tau = compute_requirement_induced_failure_time_tauB(req.margin_series, dt);
area = compute_requirement_induced_bubble_area_AB(req.lambda_max_PR_series, Gamma_req, dt);

cand = struct();
cand.pair = reshape(pair_sel, 1, 2);
cand.Xi_B = bubble.Xi_B;
cand.R_B = bubble.R_B;
cand.idx_min = bubble.idx_min;
cand.is_bubble = bubble.is_bubble;
cand.tau_B_idx = tau.tau_B_idx;
cand.tau_B_time_s = tau.tau_B_time_s;
cand.has_failure = tau.has_failure;
cand.A_B = area.A_B;
cand.margin_series = req.margin_series;
cand.lambda_max_PR_series = req.lambda_max_PR_series;
cand.M_G = MG_cur.M_G;
cand.switch_cost = local_switch_cost(pair_sel, prev_pair);
cand.resource_cost = 2; % fixed double-satellite cost for now
end

function c = local_switch_cost(pair_sel, prev_pair)
if isempty(prev_pair)
    c = 0;
    return;
end
c = double(any(sort(pair_sel(:)) ~= sort(prev_pair(:))));
end
