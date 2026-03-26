function agg_table = aggregate_over_region_phase(grid_table, group_keys, metric_names, aggregate_modes)
%AGGREGATE_OVER_REGION_PHASE Aggregate metrics over expanded region-phase scenarios.
%
% Inputs:
%   grid_table       : truth table containing expanded region-phase rows
%   group_keys       : cellstr/string of keys to group by, e.g. {'base_design_id','P','T','Ns'}
%   metric_names     : cellstr/string of metric columns, e.g. {'DG_rob','pass_ratio'}
%   aggregate_modes  : cellstr/string of aggregate modes, e.g. {'min','max','mean'}
%
% Output:
%   agg_table        : grouped summary table

if nargin < 2 || isempty(group_keys)
    group_keys = {'base_design_id'};
end
if nargin < 3 || isempty(metric_names)
    metric_names = {'DG_rob','pass_ratio'};
end
if nargin < 4 || isempty(aggregate_modes)
    aggregate_modes = {'min','max','mean'};
end

group_keys = local_to_cellstr(group_keys);
metric_names = local_to_cellstr(metric_names);
aggregate_modes = local_to_cellstr(aggregate_modes);

for i = 1:numel(group_keys)
    if ~ismember(group_keys{i}, grid_table.Properties.VariableNames)
        error('aggregate_over_region_phase:MissingGroupKey', ...
            'Missing group key: %s', group_keys{i});
    end
end

for i = 1:numel(metric_names)
    if ~ismember(metric_names{i}, grid_table.Properties.VariableNames)
        error('aggregate_over_region_phase:MissingMetric', ...
            'Missing metric: %s', metric_names{i});
    end
end

[G, group_tbl] = findgroups(grid_table(:, group_keys));
agg_table = group_tbl;

for i = 1:numel(metric_names)
    metric = metric_names{i};
    values = grid_table.(metric);

    for j = 1:numel(aggregate_modes)
        mode = lower(string(aggregate_modes{j}));
        out_name = sprintf('%s_%s', char(mode), metric);

        switch mode
            case "min"
                agg_values = splitapply(@min, values, G);
            case "max"
                agg_values = splitapply(@max, values, G);
            case "mean"
                agg_values = splitapply(@mean, values, G);
            otherwise
                error('aggregate_over_region_phase:UnsupportedMode', ...
                    'Unsupported aggregate mode: %s', mode);
        end

        agg_table.(out_name) = agg_values;
    end
end

if ismember('raan_deg', grid_table.Properties.VariableNames)
    agg_table.min_raan_deg = splitapply(@min, grid_table.raan_deg, G);
    agg_table.max_raan_deg = splitapply(@max, grid_table.raan_deg, G);
    agg_table.n_region_phase = splitapply(@numel, grid_table.raan_deg, G);
end
end

function c = local_to_cellstr(x)
if ischar(x) || isstring(x)
    c = cellstr(string(x));
elseif iscell(x)
    c = cellfun(@char, cellstr(string(x)), 'UniformOutput', false);
else
    error('aggregate_over_region_phase:InvalidInput', ...
        'Expected char/string/cell input.');
end
end
