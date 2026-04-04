function rmse = eval_rmse_metrics(state_trace)
%EVAL_RMSE_METRICS  Minimal RMSE proxy metrics for Chapter 5 R2/R4.
%
% Current note:
% This is a placeholder proxy, not a physical filter RMSE.
% It preserves the output interface for later replacement.

lambda_min = state_trace.lambda_min(:);
safe_lambda = max(lambda_min, 1e-6);

rmse_series = sqrt(1 ./ safe_lambda);

rmse = struct();
rmse.series = rmse_series;
rmse.mean_rmse = mean(rmse_series);
rmse.max_rmse = max(rmse_series);
rmse.min_rmse = min(rmse_series);
end
