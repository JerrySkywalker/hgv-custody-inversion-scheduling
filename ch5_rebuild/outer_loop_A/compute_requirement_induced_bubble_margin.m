function out = compute_requirement_induced_bubble_margin(margin_series)
%COMPUTE_REQUIREMENT_INDUCED_BUBBLE_MARGIN Requirement-induced bubble margin.
%
% Inputs:
%   margin_series : [H x 1], margin = Gamma_req - lambda_max(P_r^+)
%
% Outputs:
%   out.Xi_B          : min future requirement margin
%   out.R_B           : max(0, -Xi_B)
%   out.idx_min       : first index attaining Xi_B
%   out.is_bubble     : Xi_B <= 0
%
% Definition:
%   Xi_B = min_{ell=1,...,H} margin_series(ell)
%   R_B  = [-Xi_B]_+

margin_series = margin_series(:);
assert(isnumeric(margin_series) && isvector(margin_series) && ~isempty(margin_series), ...
    'margin_series must be a non-empty numeric vector.');

[Xi_B, idx_min] = min(margin_series);
R_B = max(0, -Xi_B);

out = struct();
out.Xi_B = Xi_B;
out.R_B = R_B;
out.idx_min = idx_min;
out.is_bubble = (Xi_B <= 0);
end
