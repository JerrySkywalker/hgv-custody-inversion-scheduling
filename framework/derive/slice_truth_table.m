function slice_table = slice_truth_table(grid_table, slice_spec)
%SLICE_TRUTH_TABLE Apply fixed filters and optional column/sort rules to a truth table.

if nargin < 2 || isempty(slice_spec)
    slice_spec = struct();
end
assert(istable(grid_table), 'slice_truth_table:InvalidInput', ...
    'grid_table must be a table.');

slice_table = grid_table;

if isfield(slice_spec, 'fixed_filters') && ~isempty(slice_spec.fixed_filters)
    filter_names = fieldnames(slice_spec.fixed_filters);
    for k = 1:numel(filter_names)
        name = filter_names{k};
        value = slice_spec.fixed_filters.(name);
        assert(ismember(name, slice_table.Properties.VariableNames), ...
            'slice_truth_table:UnknownFilter', ...
            'Unknown filter field: %s', name);
        col = slice_table.(name);
        if isstring(col) || ischar(col) || iscellstr(col)
            mask = string(col) == string(value);
        else
            mask = (col == value);
        end
        slice_table = slice_table(mask, :);
    end
end

if isfield(slice_spec, 'keep_columns') && ~isempty(slice_spec.keep_columns)
    keep = slice_spec.keep_columns;
    keep = keep(ismember(keep, slice_table.Properties.VariableNames));
    slice_table = slice_table(:, keep);
end

if isfield(slice_spec, 'sort_columns') && ~isempty(slice_spec.sort_columns)
    sort_dirs = 'ascend';
    if isfield(slice_spec, 'sort_directions') && ~isempty(slice_spec.sort_directions)
        sort_dirs = slice_spec.sort_directions;
    end
    slice_table = sortrows(slice_table, slice_spec.sort_columns, sort_dirs);
end
end
