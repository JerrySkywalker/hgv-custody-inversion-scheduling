function out = compute_raw_metric_MR(PR_plus_k, PR_minus_kp1, dt)
%COMPUTE_RAW_METRIC_MR Compute raw demand-expansion metric M_R.
%
% Current minimal engineering definition:
%   M_R(k) = (trace(P_R^-(k+1)) - trace(P_R^+(k))) / dt
%
% Inputs:
%   PR_plus_k    : demand-subspace covariance at posterior time k
%   PR_minus_kp1 : demand-subspace covariance at prior time k+1
%   dt           : step size
%
% Outputs:
%   out.M_R
%   out.trace_PR_plus
%   out.trace_PR_minus
%   out.delta_trace

assert(isnumeric(PR_plus_k) && ismatrix(PR_plus_k), 'PR_plus_k must be a matrix.');
assert(isnumeric(PR_minus_kp1) && ismatrix(PR_minus_kp1), 'PR_minus_kp1 must be a matrix.');
assert(all(size(PR_plus_k) == size(PR_minus_kp1)), 'PR size mismatch.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt must be positive.');

PR_plus_k = 0.5 * (PR_plus_k + PR_plus_k.');
PR_minus_kp1 = 0.5 * (PR_minus_kp1 + PR_minus_kp1.');

trace_plus = trace(PR_plus_k);
trace_minus = trace(PR_minus_kp1);
delta_trace = trace_minus - trace_plus;

out = struct();
out.M_R = delta_trace / dt;
out.trace_PR_plus = trace_plus;
out.trace_PR_minus = trace_minus;
out.delta_trace = delta_trace;
end
