function heatmap_out = build_heatmap_slice(grid_table, metric_name, fixed_filters, row_key, col_key)
%BUILD_HEATMAP_SLICE Build a 2D heatmap slice from a truth table.
%
% Inputs:
%   grid_table     : truth table
%   metric_name    : metric column name, e.g. 'DG_rob', 'pass_ratio', 'feasible_flag'
%   fixed_filters  : struct of equality filters, e.g. struct('i_deg',60)
%   row_key        : row axis field, e.g. 'P'
%   col_key        : col axis field, e.g. 'T'
%
% Output:
%   heatmap_out : struct with
%       .row_key
%       .col_key
%       .metric_name
%       .fixed_filters
%       .row_values
%       .col_values
%       .value_matrix
%       .slice_table

if nargin < 2 || isempty(metric_name)
    metric_name = 'pass_ratio';
end
if nargin < 3
    fixed_filters = struct();
end
if nargin < 4 || isempty(row_key)
    row_key = 'P';
end
if nargin < 5 || isempty(col_key)
    col_key = 'T';
end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));

if isempty(slice_table)
    error('build_heatmap_slice:EmptySlice', ...
        'No rows remain after applying fixed_filters.');
end

required_vars = {row_key, col_key, metric_name};
for i = 1:numel(required_vars)
    v = required_vars{i};
    if ~ismember(v, slice_table.Properties.VariableNames)
        error('build_heatmap_slice:MissingVariable', ...
            'Missing required variable in slice table: %s', v);
    end
end

row_values = unique(slice_table.(row_key));
col_values = unique(slice_table.(col_key));

row_values = sort(row_values(:));
col_values = sort(col_values(:));

value_matrix = nan(numel(row_values), numel(col_values));

for i = 1:numel(row_values)
    for j = 1:numel(col_values)
        mask = slice_table.(row_key) == row_values(i) & slice_table.(col_key) == col_values(j);
        tmp = slice_table(mask, :);

        if isempty(tmp)
            value_matrix(i, j) = NaN;
        elseif height(tmp) == 1
            value_matrix(i, j) = tmp.(metric_name);
        else
            % For duplicated points, take the first one deterministically.
            value_matrix(i, j) = tmp.(metric_name)(1);
        end
    end
end

heatmap_out = struct();
heatmap_out.row_key = row_key;
heatmap_out.col_key = col_key;
heatmap_out.metric_name = metric_name;
heatmap_out.fixed_filters = fixed_filters;
heatmap_out.row_values = row_values;
heatmap_out.col_values = col_values;
heatmap_out.value_matrix = value_matrix;
heatmap_out.slice_table = slice_table;
end
