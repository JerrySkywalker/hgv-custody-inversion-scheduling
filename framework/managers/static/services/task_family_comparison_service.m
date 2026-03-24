function comparison_result = task_family_comparison_service(family_results)
if nargin < 1 || isempty(family_results)
    error('task_family_comparison_service:InvalidInput', ...
        'family_results is required.');
end

n = numel(family_results);

first_row = local_build_summary_row(family_results{1});
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
case_count = item.task_family.case_count;
tbl = item.truth_result.table;

design_count = height(tbl);
feasible_count = sum(tbl.is_feasible);
feasible_ratio = feasible_count / max(design_count, 1);

if feasible_count > 0
    feasible_tbl = tbl(tbl.is_feasible, :);
    min_Ns = min(feasible_tbl.Ns);
else
    feasible_tbl = tbl([],:);
    min_Ns = NaN;
end

max_joint_margin = max(tbl.joint_margin);
min_joint_margin = min(tbl.joint_margin);
mean_joint_margin = mean(tbl.joint_margin);

[~, idx_best] = max(tbl.rank_score);
best_design_id = char(tbl.design_id(idx_best));
best_rank_score = tbl.rank_score(idx_best);

row = struct();
row.family_name = family_name;
row.case_count = case_count;
row.design_count = design_count;
row.feasible_count = feasible_count;
row.feasible_ratio = feasible_ratio;
row.min_Ns = min_Ns;
row.max_joint_margin = max_joint_margin;
row.min_joint_margin = min_joint_margin;
row.mean_joint_margin = mean_joint_margin;
row.best_design_id = best_design_id;
row.best_rank_score = best_rank_score;
end
