function S = compute_ch5r_metric_summary(x)
%COMPUTE_CH5R_METRIC_SUMMARY
% Return min / q1 / median / mean / q3 / max / std / upper_quartile_mean.

x = x(:);
x = x(isfinite(x));

S = struct( ...
    'min', NaN, ...
    'q1', NaN, ...
    'median', NaN, ...
    'mean', NaN, ...
    'q3', NaN, ...
    'max', NaN, ...
    'std', NaN, ...
    'upper_quartile_mean', NaN, ...
    'n', 0);

if isempty(x)
    return;
end

S.n = numel(x);
S.min = min(x);
S.q1 = prctile(x, 25);
S.median = median(x);
S.mean = mean(x);
S.q3 = prctile(x, 75);
S.max = max(x);

if numel(x) == 1
    S.std = 0;
else
    S.std = std(x);
end

uq = x(x >= S.q3);
if isempty(uq)
    S.upper_quartile_mean = NaN;
else
    S.upper_quartile_mean = mean(uq);
end
end
