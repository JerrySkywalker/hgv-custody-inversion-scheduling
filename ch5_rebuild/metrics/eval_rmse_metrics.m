function out = eval_rmse_metrics(xhat_plus_series, xtruth_series, Pplus_series, Sp)
%EVAL_RMSE_METRICS Evaluate truth-RMSE and covariance-RMSE series.
%
% Inputs:
%   xhat_plus_series : [N x nx]
%   xtruth_series    : [N x nx]
%   Pplus_series     : [nx x nx x N]
%   Sp               : [np x nx] position selection/projection
%
% Outputs:
%   out.rmse_truth_series
%   out.rmse_cov_series
%   out.mean_rmse_truth
%   out.mean_rmse_cov
%   out.max_rmse_truth
%   out.max_rmse_cov

assert(isnumeric(xhat_plus_series) && ismatrix(xhat_plus_series), 'xhat_plus_series invalid.');
assert(isnumeric(xtruth_series) && ismatrix(xtruth_series), 'xtruth_series invalid.');
assert(all(size(xhat_plus_series) == size(xtruth_series)), 'state series size mismatch.');
assert(isnumeric(Pplus_series) && ndims(Pplus_series) == 3, 'Pplus_series invalid.');
assert(isnumeric(Sp) && ismatrix(Sp), 'Sp invalid.');

[N, nx] = size(xhat_plus_series);
assert(size(Pplus_series,1) == nx && size(Pplus_series,2) == nx && size(Pplus_series,3) == N, ...
    'Pplus_series size mismatch.');
assert(size(Sp,2) == nx, 'Sp dimension mismatch.');

np = size(Sp,1);
rmse_truth = zeros(N,1);
rmse_cov = zeros(N,1);

for k = 1:N
    e = xhat_plus_series(k,:).' - xtruth_series(k,:).';
    ep = Sp * e;
    rmse_truth(k) = sqrt((ep.' * ep) / np);

    Pp = Pplus_series(:,:,k);
    Pp = 0.5 * (Pp + Pp.');
    rmse_cov(k) = sqrt(trace(Sp * Pp * Sp.'));
end

out = struct();
out.rmse_truth_series = rmse_truth;
out.rmse_cov_series = rmse_cov;
out.mean_rmse_truth = mean(rmse_truth);
out.mean_rmse_cov = mean(rmse_cov);
out.max_rmse_truth = max(rmse_truth);
out.max_rmse_cov = max(rmse_cov);
end
