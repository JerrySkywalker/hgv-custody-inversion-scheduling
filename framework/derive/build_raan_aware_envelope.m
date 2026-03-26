function env_table = build_raan_aware_envelope(grid_table, group_key, metric_name, fixed_filters, scenario_metric, scenario_mode)
%BUILD_RAAN_AWARE_ENVELOPE Envelope after aggregating over region-phase scenarios.
%
% Example:
%   build_raan_aware_envelope(grid_table, 'Ns', 'DG_rob', struct('i_deg',60), 'DG_rob', 'min')
%
% Inputs:
%   grid_table       : expanded truth table
%   group_key        : envelope grouping key, e.g. 'Ns'
%   metric_name      : envelope metric after scenario aggregation, e.g. 'DG_rob'
%   fixed_filters    : filters before aggregation, e.g. struct('i_deg',60)
%   scenario_metric  : metric to aggregate over RAAN, e.g. 'DG_rob' or 'pass_ratio'
%   scenario_mode    : 'min' | 'max' | 'mean'
%
% Output:
%   env_table        : table

if nargin < 2 || isempty(group_key), group_key = 'Ns'; end
if nargin < 3 || isempty(metric_name), metric_name = 'DG_rob'; end
if nargin < 4, fixed_filters = struct(); end
if nargin < 5 || isempty(scenario_metric), scenario_metric = metric_name; end
if nargin < 6 || isempty(scenario_mode), scenario_mode = 'min'; end

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
    error('build_raan_aware_envelope:MissingAggregatedMetric', ...
        'Missing aggregated metric column: %s', agg_metric_name);
end

agg = renamevars(agg, agg_metric_name, metric_name);

env_table = build_best_envelope(agg, group_key, metric_name, struct(), 'max');
end
