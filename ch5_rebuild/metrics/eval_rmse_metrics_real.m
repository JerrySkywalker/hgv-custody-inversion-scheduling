function rmse_proxy_metrics = eval_rmse_metrics_real(wininfo)
%EVAL_RMSE_METRICS_REAL
% Fisher-based RMSE proxy on the real R1.5/R3/R4 line.
%
% Important:
% This is NOT a physical filter RMSE.
% It is only a monotone proxy based on rolling/centered-window Fisher information:
%
%   rmse_proxy = sqrt(1 / max(lambda_min(J_W), eps))
%
% Summary statistics are computed ONLY on valid_for_bubble samples.

if nargin < 1 || isempty(wininfo)
    error('wininfo is required.');
end

lambda_min = wininfo.lambda_min(:);
safe_lambda = max(lambda_min, 1e-12);
rmse_series = sqrt(1 ./ safe_lambda);

if isfield(wininfo, 'valid_for_bubble') && ~isempty(wininfo.valid_for_bubble)
    valid_for_bubble = logical(wininfo.valid_for_bubble(:));
else
    valid_for_bubble = true(size(rmse_series));
end

assert(numel(rmse_series) == numel(valid_for_bubble), ...
    'rmse_series and valid_for_bubble size mismatch.');

valid_rmse = rmse_series(valid_for_bubble);

rmse_proxy_metrics = struct();
rmse_proxy_metrics.series = rmse_series;
rmse_proxy_metrics.valid_for_bubble = valid_for_bubble;

if isempty(valid_rmse)
    rmse_proxy_metrics.mean_rmse_proxy = NaN;
    rmse_proxy_metrics.max_rmse_proxy = NaN;
    rmse_proxy_metrics.min_rmse_proxy = NaN;
else
    rmse_proxy_metrics.mean_rmse_proxy = mean(valid_rmse, 'omitnan');
    rmse_proxy_metrics.max_rmse_proxy = max(valid_rmse, [], 'omitnan');
    rmse_proxy_metrics.min_rmse_proxy = min(valid_rmse, [], 'omitnan');
end

rmse_proxy_metrics.note = 'Fisher-based RMSE proxy; not physical filter RMSE.';
end
