function req = eval_requirement_margin(state_trace)
%EVAL_REQUIREMENT_MARGIN  Minimal requirement-margin proxy for Phase R2.
%
% Current Phase R2 note:
% This is not yet a physical covariance projection result.
% It is a proxy interface used to prepare later linkage:
%
%   lambda_min(Y_W) down  => requirement margin down
%
% Proxy definition:
%   margin(k) = lambda_min(k) - gamma_req

if nargin < 1 || isempty(state_trace)
    error('state_trace is required.');
end

lambda_min = state_trace.lambda_min(:);
gamma_req = state_trace.gamma_req;

margin = lambda_min - gamma_req;
is_violation = margin < 0;

req = struct();
req.margin = margin;
req.is_violation = is_violation;
req.min_margin = min(margin);
req.mean_margin = mean(margin);
req.total_violation_steps = nnz(is_violation);
end
