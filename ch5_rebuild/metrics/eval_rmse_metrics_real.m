function rmse_metrics = eval_rmse_metrics_real(wininfo)
%EVAL_RMSE_METRICS_REAL
% RMSE proxy on the real R3/R4 line based on the rolling-window Fisher matrix.
%
% Current proxy:
%   rmse_proxy = sqrt(1 / max(lambda_min(J_W), eps))

if nargin < 1 || isempty(wininfo)
    error('wininfo is required.');
end

lambda_min = wininfo.lambda_min(:);
safe_lambda = max(lambda_min, 1e-12);
rmse_series = sqrt(1 ./ safe_lambda);

rmse_metrics = struct();
rmse_metrics.series = rmse_series;
rmse_metrics.mean_rmse = mean(rmse_series, 'omitnan');
rmse_metrics.max_rmse = max(rmse_series, [], 'omitnan');
rmse_metrics.min_rmse = min(rmse_series, [], 'omitnan');
end
