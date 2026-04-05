function out = compute_requirement_induced_failure_time_tauB(margin_series, dt)
%COMPUTE_REQUIREMENT_INDUCED_FAILURE_TIME_TAUB Compute first failure time in future window.
%
% Inputs:
%   margin_series : [H x 1], margin = Gamma_req - lambda_max(P_r^+)
%   dt            : time step
%
% Outputs:
%   out.tau_B_idx     : first index with margin <= 0, or inf if none
%   out.tau_B_time_s  : first failure time in seconds, or inf if none
%   out.has_failure   : logical

margin_series = margin_series(:);

assert(isnumeric(margin_series) && isvector(margin_series) && ~isempty(margin_series), ...
    'margin_series must be a non-empty numeric vector.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt must be positive.');

idx = find(margin_series <= 0, 1, 'first');

out = struct();
if isempty(idx)
    out.tau_B_idx = inf;
    out.tau_B_time_s = inf;
    out.has_failure = false;
else
    out.tau_B_idx = idx;
    out.tau_B_time_s = idx * dt;
    out.has_failure = true;
end
end
