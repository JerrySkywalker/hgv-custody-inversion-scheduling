function compare_table = compare_truth_tables(left_table, right_table, join_keys, compare_spec)
%COMPARE_TRUTH_TABLES Join and compare two truth tables on shared keys.

if nargin < 4 || isempty(compare_spec)
    compare_spec = struct();
end

assert(istable(left_table) && istable(right_table), ...
    'compare_truth_tables:InvalidInput', ...
    'Both inputs must be tables.');

if nargin < 3 || isempty(join_keys)
    join_keys = {'design_id'};
end

if ~isfield(compare_spec, 'metric_columns') || isempty(compare_spec.metric_columns)
    compare_spec.metric_columns = {'design_id', 'pass_ratio', 'is_feasible', 'feasible_flag', 'joint_margin'};
end
if ~isfield(compare_spec, 'left_prefix') || isempty(compare_spec.left_prefix)
    compare_spec.left_prefix = 'left';
end
if ~isfield(compare_spec, 'right_prefix') || isempty(compare_spec.right_prefix)
    compare_spec.right_prefix = 'right';
end

left_metrics = intersect(compare_spec.metric_columns, left_table.Properties.VariableNames, 'stable');
right_metrics = intersect(compare_spec.metric_columns, right_table.Properties.VariableNames, 'stable');

left_keep = unique([join_keys, setdiff(left_metrics, join_keys, 'stable')], 'stable');
right_keep = unique([join_keys, setdiff(right_metrics, join_keys, 'stable')], 'stable');

left_tbl = left_table(:, left_keep);
right_tbl = right_table(:, right_keep);

left_rename = setdiff(left_keep, join_keys, 'stable');
right_rename = setdiff(right_keep, join_keys, 'stable');

if ~isempty(left_rename)
    left_tbl = renamevars(left_tbl, left_rename, strcat(compare_spec.left_prefix, "_", left_rename));
end
if ~isempty(right_rename)
    right_tbl = renamevars(right_tbl, right_rename, strcat(compare_spec.right_prefix, "_", right_rename));
end

compare_table = innerjoin(left_tbl, right_tbl, 'Keys', join_keys);

left_pass = sprintf('%s_pass_ratio', compare_spec.left_prefix);
right_pass = sprintf('%s_pass_ratio', compare_spec.right_prefix);
if ismember(left_pass, compare_table.Properties.VariableNames) && ismember(right_pass, compare_table.Properties.VariableNames)
    compare_table.abs_diff_pass_ratio = abs(compare_table.(left_pass) - compare_table.(right_pass));
end

left_feas = local_pick_feasible_var(compare_table, compare_spec.left_prefix);
right_feas = local_pick_feasible_var(compare_table, compare_spec.right_prefix);
if ismember(left_feas, compare_table.Properties.VariableNames) && ismember(right_feas, compare_table.Properties.VariableNames)
    compare_table.feasible_match = compare_table.(left_feas) == compare_table.(right_feas);
end

left_margin = sprintf('%s_joint_margin', compare_spec.left_prefix);
right_margin = sprintf('%s_joint_margin', compare_spec.right_prefix);
if ismember(left_margin, compare_table.Properties.VariableNames) && ismember(right_margin, compare_table.Properties.VariableNames)
    compare_table.joint_margin_diff = compare_table.(left_margin) - compare_table.(right_margin);
end
end

function var_name = local_pick_feasible_var(tbl, prefix)
preferred = {sprintf('%s_is_feasible', prefix), sprintf('%s_feasible_flag', prefix)};
var_name = preferred{1};
for k = 1:numel(preferred)
    if ismember(preferred{k}, tbl.Properties.VariableNames)
        var_name = preferred{k};
        return;
    end
end
end
