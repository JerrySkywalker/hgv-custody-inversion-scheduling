function out = compute_requirement_induced_bubble_area_AB(lambda_max_PR_series, Gamma_req, dt)
%COMPUTE_REQUIREMENT_INDUCED_BUBBLE_AREA_AB Compute requirement-violation area over future window.
%
% Inputs:
%   lambda_max_PR_series : [H x 1]
%   Gamma_req            : scalar requirement bound
%   dt                   : time step
%
% Outputs:
%   out.A_B              : violation area
%   out.excess_series    : [H x 1], excess over requirement
%
% Definition:
%   A_B = sum_{ell=1}^H [lambda_max(P_r^+) - Gamma_req]_+ * dt

lambda_max_PR_series = lambda_max_PR_series(:);

assert(isnumeric(lambda_max_PR_series) && isvector(lambda_max_PR_series) && ~isempty(lambda_max_PR_series), ...
    'lambda_max_PR_series must be a non-empty numeric vector.');
assert(isnumeric(Gamma_req) && isscalar(Gamma_req) && isfinite(Gamma_req), 'Gamma_req invalid.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt invalid.');

excess_series = max(lambda_max_PR_series - Gamma_req, 0);

out = struct();
out.A_B = sum(excess_series) * dt;
out.excess_series = excess_series;
end
