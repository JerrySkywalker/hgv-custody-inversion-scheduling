function comparison_result = task_family_comparison_service(family_results)
if nargin < 1 || isempty(family_results)
    error('task_family_comparison_service:InvalidInput', ...
        'family_results is required.');
end

n = numel(family_results);

% Build first row to establish struct schema
first_row = local_build_summary_row(family_results{1});

% Preallocate with matching fields
summary_rows = repmat(first_row, n, 1);

for k = 2:n
    summary_rows(k) = local_build_summary_row(family_results{k});
end

summary_table = struct2table(summary_rows);

comparison_result = struct();
comparison_result.rows = summary_rows;
comparison_result.table = summary_table;
comparison_result.family_count = n;
comparison_result.meta = struct('status', 'ok');
end

function row = local_build_summary_row(item)
family_name = item.task_family.name;
tbl = item.truth_result.table;

design_count = height(tbl);
feasible_count = sum(tbl.is_feasible);
feasible_ratio = feasible_count / max(design_count, 1);

if feasible_count > 0
    feasible_tbl = tbl(tbl.is_feasible, :);
    min_Ns = min(feasible_tbl.Ns);
else
    min_Ns = NaN;
end

max_joint_margin = max(tbl.joint_margin);

row = struct();
row.family_name = family_name;
row.design_count = design_count;
row.feasible_count = feasible_count;
row.feasible_ratio = feasible_ratio;
row.min_Ns = min_Ns;
row.max_joint_margin = max_joint_margin;
end
