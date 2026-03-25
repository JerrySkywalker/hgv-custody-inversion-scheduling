function boundary_result = summarize_boundary(truth_table, summary_spec)
%SUMMARIZE_BOUNDARY Build boundary summary tables from a truth table.

if nargin < 2 || isempty(summary_spec)
    summary_spec = struct();
end
assert(istable(truth_table), 'summarize_boundary:InvalidInput', ...
    'truth_table must be a table.');

feasible_col = local_default_feasible_column(truth_table, summary_spec);
margin_col = local_get_option(summary_spec, 'margin_column', 'joint_margin');
critical_threshold = local_get_option(summary_spec, 'critical_threshold', 1.0);
saturated_threshold = local_get_option(summary_spec, 'saturated_threshold', 2.0);

assert(ismember(feasible_col, truth_table.Properties.VariableNames), ...
    'summarize_boundary:MissingFeasibleColumn', ...
    'Missing feasible column: %s', feasible_col);
assert(ismember(margin_col, truth_table.Properties.VariableNames), ...
    'summarize_boundary:MissingMarginColumn', ...
    'Missing margin column: %s', margin_col);

feasible_mask = truth_table.(feasible_col) == true;
feasible_tbl = truth_table(feasible_mask, :);

if isempty(feasible_tbl)
    min_Ns = NaN;
    minimum_feasible_table = truth_table([], :);
else
    min_Ns = min(feasible_tbl.Ns);
    minimum_feasible_table = feasible_tbl(feasible_tbl.Ns == min_Ns, :);
end

critical_boundary_table = truth_table(feasible_mask & truth_table.(margin_col) <= critical_threshold, :);
failed_table = truth_table(~feasible_mask, :);
saturated_table = truth_table(truth_table.(margin_col) >= saturated_threshold, :);

summary = struct();
summary.design_count = height(truth_table);
summary.feasible_count = sum(feasible_mask);
summary.failed_count = sum(~feasible_mask);
summary.feasible_ratio = mean(double(feasible_mask));
summary.min_Ns = min_Ns;
summary.min_design_count = height(minimum_feasible_table);
summary.critical_count = height(critical_boundary_table);
summary.saturated_count = height(saturated_table);

boundary_result = struct();
boundary_result.minimum_feasible_table = minimum_feasible_table;
boundary_result.critical_boundary_table = critical_boundary_table;
boundary_result.failed_table = failed_table;
boundary_result.saturated_table = saturated_table;
boundary_result.summary_table = struct2table(summary);
end

function value = local_get_option(summary_spec, name, default_value)
if isfield(summary_spec, name) && ~isempty(summary_spec.(name))
    value = summary_spec.(name);
else
    value = default_value;
end
end

function feasible_col = local_default_feasible_column(truth_table, summary_spec)
if isfield(summary_spec, 'feasible_column') && ~isempty(summary_spec.feasible_column)
    feasible_col = summary_spec.feasible_column;
elseif ismember('is_feasible', truth_table.Properties.VariableNames)
    feasible_col = 'is_feasible';
elseif ismember('feasible_flag', truth_table.Properties.VariableNames)
    feasible_col = 'feasible_flag';
else
    feasible_col = 'is_feasible';
end
end
