function group_result = group_truth_table_by_key(grid_table, group_keys, fixed_filters)
%GROUP_TRUTH_TABLE_BY_KEY Group a truth table by one or more key columns.

if nargin < 3
    fixed_filters = struct();
end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));

if ischar(group_keys) || isstring(group_keys)
    group_keys = cellstr(group_keys);
end

assert(istable(slice_table), 'group_truth_table_by_key:InvalidInput', ...
    'grid_table must be a table.');

[G, key_table] = findgroups(slice_table(:, group_keys));
groups = cell(max(G), 1);
for k = 1:max(G)
    groups{k} = slice_table(G == k, :);
end

group_result = struct();
group_result.key_table = key_table;
group_result.groups = groups;
group_result.group_count = numel(groups);
group_result.slice_table = slice_table;
end
