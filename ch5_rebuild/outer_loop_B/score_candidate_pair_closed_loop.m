function out = score_candidate_pair_closed_loop(pred, pair, sat_pos, x_seq, F_seq, Cr, R_pair, ...
    weights, prev_pair, cfgScore)
%SCORE_CANDIDATE_PAIR_CLOSED_LOOP Evaluate one candidate pair for outerB.
%
% Updated in R8.5b:
%   return raw components first, and let selector normalize across candidate bank.
%
% Output fields:
%   out.raw_MG
%   out.raw_lambda_max_PR_plus
%   out.raw_switch_cost
%   out.raw_resource_cost
%   out.tie_metric
%   out.H_pair
%   out.W_pair
%   out.Wr_pair
%   out.traceWr

assert(isstruct(pred) && isfield(pred, 'x_minus') && isfield(pred, 'P_minus'), 'Invalid pred.');
assert(isnumeric(pair) && numel(pair) == 2, 'pair must have 2 elements.');
assert(isnumeric(sat_pos) && size(sat_pos,1) == 3, 'sat_pos must be [3 x Ns].');
assert(isnumeric(x_seq) && ismatrix(x_seq), 'x_seq must be matrix.');
assert(isnumeric(F_seq) && ndims(F_seq) == 3, 'F_seq must be 3D array.');
assert(isnumeric(Cr) && ismatrix(Cr), 'Cr invalid.');
assert(isnumeric(R_pair) && all(size(R_pair) == [6 6]), 'R_pair must be [6x6].');
assert(isstruct(weights), 'weights invalid.');
assert(isstruct(cfgScore), 'cfgScore invalid.');

nx = numel(pred.x_minus);
pair = pair(:).';
p_now = pred.x_minus(1:3);

H_pair = local_build_pair_H(p_now, pair, sat_pos, nx);

% hypothetical posterior covariance under this pair
P_minus = pred.P_minus;
S_pair = H_pair * P_minus * H_pair.' + R_pair;
K_pair = (P_minus * H_pair.') / S_pair;
I = eye(nx);
P_plus_hyp = (I - K_pair * H_pair) * P_minus * (I - K_pair * H_pair).' + K_pair * R_pair * K_pair.';
P_plus_hyp = 0.5 * (P_plus_hyp + P_plus_hyp.');

PR_plus_hyp = compute_requirement_cov_PR(P_plus_hyp, Cr);
lambda_max_PR_plus = max(real(eig(PR_plus_hyp)));

% pair-specific dynamic Gramian over predicted window
H_fun_pair = @(x) local_build_pair_H(x(1:3), pair, sat_pos, nx);
W_pair = compute_predicted_window_gramian(F_seq, x_seq, H_fun_pair, R_pair);
MG_pair = compute_structural_metric_MG(W_pair, Cr);

if isempty(prev_pair)
    switch_cost = 0;
else
    switch_cost = cfgScore.switch_cost * double(any(sort(prev_pair) ~= sort(pair)));
end

resource_cost = cfgScore.resource_cost;

% tie-break: prefer higher structure and lower posterior requirement covariance
tie_metric = MG_pair.M_G / (lambda_max_PR_plus + 1e-9);

out = struct();
out.raw_MG = MG_pair.M_G;
out.raw_lambda_max_PR_plus = lambda_max_PR_plus;
out.raw_switch_cost = switch_cost;
out.raw_resource_cost = resource_cost;
out.tie_metric = tie_metric;

out.H_pair = H_pair;
out.W_pair = W_pair;
out.Wr_pair = MG_pair.Wr;
out.traceWr = MG_pair.trace_Wr;
end

function H_pair = local_build_pair_H(p_tgt, pair, sat_pos, nx)
H_pair = zeros(6, nx);

for a = 1:2
    idx = pair(a);
    r_sat = sat_pos(:, idx);
    los = p_tgt - r_sat;
    los = los / max(norm(los), 1e-9);

    ez = [0;0;1];
    q = 1 - abs(dot(los, ez));
    q = max(q, 0.05);

    G = eye(3) - los * los.';
    Hi = [q * G, zeros(3, nx - 3)];
    H_pair((3*(a-1)+1):(3*a), :) = Hi;
end
end
