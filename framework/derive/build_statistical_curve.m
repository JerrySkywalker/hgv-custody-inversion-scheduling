function curve_table = build_statistical_curve(grid_table, group_key, metric_name, fixed_filters, stats_spec)
%BUILD_STATISTICAL_CURVE Build grouped statistics such as mean/min/max/quantile.

if nargin < 2 || isempty(group_key)
    group_key = 'Ns';
end
if nargin < 3 || isempty(metric_name)
    metric_name = 'pass_ratio';
end
if nargin < 4
    fixed_filters = struct();
end
if nargin < 5 || isempty(stats_spec)
    stats_spec = struct('stats', {{'mean', 'min', 'max'}});
end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));
group_values = unique(slice_table.(group_key));
group_values = sort(group_values(:));

rows = repmat(struct(), numel(group_values), 1);
for k = 1:numel(group_values)
    value = group_values(k);
    tmp = slice_table(slice_table.(group_key) == value, :);
    vals = tmp.(metric_name);

    rows(k).(group_key) = value;
    stats_list = stats_spec.stats;
    for i = 1:numel(stats_list)
        stat_name = lower(string(stats_list{i}));
        switch stat_name
            case "mean"
                rows(k).mean = mean(vals, 'omitnan');
            case "min"
                rows(k).min = min(vals);
            case "max"
                rows(k).max = max(vals);
            case "quantile"
                q = 0.5;
                if isfield(stats_spec, 'quantile') && ~isempty(stats_spec.quantile)
                    q = stats_spec.quantile;
                end
                rows(k).quantile = quantile(vals, q);
            otherwise
                error('build_statistical_curve:UnsupportedStat', ...
                    'Unsupported stat: %s', stat_name);
        end
    end
end

curve_table = struct2table(rows);
end
