function out = compute_requirement_margin_series_forecast(Pplus_seq, Cr, Gamma_req)
%COMPUTE_REQUIREMENT_MARGIN_SERIES_FORECAST Forecast requirement margin series.
%
% Inputs:
%   Pplus_seq  : [nx x nx x H] forecast posterior covariance sequence
%   Cr         : [nr x nx] requirement projection matrix
%   Gamma_req  : scalar requirement upper bound
%
% Outputs:
%   out.margin_series         : [H x 1], margin = Gamma_req - lambda_max(P_r^+)
%   out.lambda_max_PR_series  : [H x 1]
%   out.PR_seq                : [nr x nr x H]

assert(isnumeric(Pplus_seq) && ndims(Pplus_seq) == 3, 'Pplus_seq must be [nx x nx x H].');
assert(isnumeric(Cr) && ismatrix(Cr), 'Cr must be numeric matrix.');
assert(isnumeric(Gamma_req) && isscalar(Gamma_req) && isfinite(Gamma_req), 'Gamma_req invalid.');

[nx, nx2, H] = size(Pplus_seq);
assert(nx == nx2, 'Pplus_seq must be square in the first two dimensions.');
assert(size(Cr,2) == nx, 'Cr second dimension must match state dimension.');

nr = size(Cr,1);
margin_series = zeros(H,1);
lambda_max_PR_series = zeros(H,1);
PR_seq = zeros(nr, nr, H);

for ell = 1:H
    Pp = Pplus_seq(:,:,ell);
    Pp = 0.5 * (Pp + Pp.');

    PR = compute_requirement_cov_PR(Pp, Cr);
    PR = 0.5 * (PR + PR.');

    lam = max(real(eig(PR)));
    margin_series(ell) = Gamma_req - lam;
    lambda_max_PR_series(ell) = lam;
    PR_seq(:,:,ell) = PR;
end

out = struct();
out.margin_series = margin_series;
out.lambda_max_PR_series = lambda_max_PR_series;
out.PR_seq = PR_seq;
end
