function out = compute_bubble_margin_XiB(S_r, D_r, eps_B)
%COMPUTE_BUBBLE_MARGIN_XIB Compute bubble margin and bubble risk.
%
% Inputs:
%   S_r   : weakest future supply floor
%   D_r   : weakest-direction cumulative demand
%   eps_B : structural safety margin
%
% Outputs:
%   out.Xi_B          : bubble margin
%   out.R_B           : bubble risk = max(0, -Xi_B)
%   out.is_bubble     : Xi_B <= 0
%
% Definition:
%   Xi_B = S_r - D_r - eps_B
%   R_B  = [-Xi_B]_+

assert(isnumeric(S_r) && isscalar(S_r) && isfinite(S_r), 'S_r invalid.');
assert(isnumeric(D_r) && isscalar(D_r) && isfinite(D_r), 'D_r invalid.');
assert(isnumeric(eps_B) && isscalar(eps_B) && isfinite(eps_B) && eps_B >= 0, 'eps_B invalid.');

Xi_B = S_r - D_r - eps_B;
R_B = max(0, -Xi_B);

out = struct();
out.Xi_B = Xi_B;
out.R_B = R_B;
out.is_bubble = (Xi_B <= 0);
end
