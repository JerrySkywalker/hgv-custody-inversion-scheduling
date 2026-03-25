function scatter_table = build_design_point_scatter(grid_table, x_metric, y_metric, fixed_filters, label_columns)
%BUILD_DESIGN_POINT_SCATTER Build a scatter table with optional point labels.

if nargin < 2 || isempty(x_metric)
    x_metric = 'Ns';
end
if nargin < 3 || isempty(y_metric)
    y_metric = 'pass_ratio';
end
if nargin < 4
    fixed_filters = struct();
end
if nargin < 5 || isempty(label_columns)
    label_columns = {'P', 'T'};
end

scatter_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));
scatter_table = sortrows(scatter_table, {x_metric}, {'ascend'});
scatter_table.x_value = scatter_table.(x_metric);
scatter_table.y_value = scatter_table.(y_metric);

labels = strings(height(scatter_table), 1);
for k = 1:height(scatter_table)
    pieces = strings(0, 1);
    for i = 1:numel(label_columns)
        name = label_columns{i};
        if ismember(name, scatter_table.Properties.VariableNames)
            pieces(end+1, 1) = sprintf('%s=%s', name, local_value_to_string(scatter_table.(name)(k))); %#ok<AGROW>
        end
    end
    labels(k) = strjoin(pieces, ', ');
end
scatter_table.point_label = labels;
end

function s = local_value_to_string(value)
if isstring(value) || ischar(value)
    s = char(string(value));
elseif isnumeric(value) || islogical(value)
    s = num2str(value);
else
    s = sprintf('<%s>', class(value));
end
end
