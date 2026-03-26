function heatmap_out = build_raan_aware_heatmap_slice(grid_table, metric_name, fixed_filters, row_key, col_key, scenario_metric, scenario_mode)
%BUILD_RAAN_AWARE_HEATMAP_SLICE Heatmap after aggregating over region-phase scenarios.
%
% Example:
%   build_raan_aware_heatmap_slice(grid_table, 'DG_rob', struct('i_deg',60), 'P', 'T', 'DG_rob', 'min')

if nargin < 2 || isempty(metric_name), metric_name = 'DG_rob'; end
if nargin < 3, fixed_filters = struct(); end
if nargin < 4 || isempty(row_key), row_key = 'P'; end
if nargin < 5 || isempty(col_key), col_key = 'T'; end
if nargin < 6 || isempty(scenario_metric), scenario_metric = metric_name; end
if nargin < 7 || isempty(scenario_mode), scenario_mode = 'min'; end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));

group_keys = {'base_design_id','P','T','Ns'};
if ismember('i_deg', slice_table.Properties.VariableNames)
    group_keys = [group_keys, {'i_deg'}];
end
if ismember('h_km', slice_table.Properties.VariableNames)
    group_keys = [group_keys, {'h_km'}];
end
if ismember('F', slice_table.Properties.VariableNames)
    group_keys = [group_keys, {'F'}];
end

agg = aggregate_over_region_phase(slice_table, group_keys, {scenario_metric}, {scenario_mode});

agg_metric_name = sprintf('%s_%s', lower(string(scenario_mode)), char(string(scenario_metric)));
if ~ismember(agg_metric_name, agg.Properties.VariableNames)
    error('build_raan_aware_heatmap_slice:MissingAggregatedMetric', ...
        'Missing aggregated metric column: %s', agg_metric_name);
end

agg = renamevars(agg, agg_metric_name, metric_name);

heatmap_out = build_heatmap_slice(agg, metric_name, struct(), row_key, col_key);
end
