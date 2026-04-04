function rmse_proxy_metrics = eval_rmse_metrics_real(wininfo)
%EVAL_RMSE_METRICS_REAL
% Fisher-based RMSE proxy on the real R3/R4 line.
%
% Important:
% This is NOT a physical filter RMSE.
% It is only a monotone proxy based on rolling-window Fisher information:
%
%   rmse_proxy = sqrt(1 / max(lambda_min(J_W), eps))
%
% It is useful for relative trend inspection, but should not be interpreted
% as a physical position RMSE in meters or kilometers.

if nargin < 1 || isempty(wininfo)
    error('wininfo is required.');
end

lambda_min = wininfo.lambda_min(:);
safe_lambda = max(lambda_min, 1e-12);
rmse_series = sqrt(1 ./ safe_lambda);

rmse_proxy_metrics = struct();
rmse_proxy_metrics.series = rmse_series;
rmse_proxy_metrics.mean_rmse_proxy = mean(rmse_series, 'omitnan');
rmse_proxy_metrics.max_rmse_proxy = max(rmse_series, [], 'omitnan');
rmse_proxy_metrics.min_rmse_proxy = min(rmse_series, [], 'omitnan');
rmse_proxy_metrics.note = 'Fisher-based RMSE proxy; not physical filter RMSE.';
end
