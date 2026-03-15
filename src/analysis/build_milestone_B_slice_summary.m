function summary_table = build_milestone_B_slice_summary(slice_results)
%BUILD_MILESTONE_B_SLICE_SUMMARY Build consolidated slice summary table.

if isempty(slice_results)
    summary_table = table();
    return;
end

rows = cell(numel(slice_results), 1);
for k = 1:numel(slice_results)
    r = slice_results{k};
    axis_1 = "";
    axis_2 = "";
    if isfield(r, 'axis_labels')
        axis_1 = string(r.axis_labels{1});
        axis_2 = string(r.axis_labels{2});
    end
    feasible_ratio = 0;
    if isfield(r, 'summary') && isfield(r.summary, 'num_grid_points') && r.summary.num_grid_points > 0
        feasible_ratio = r.summary.num_feasible_points / r.summary.num_grid_points;
    end
    rows{k} = table(string(r.slice_name), axis_1, axis_2, ...
        r.summary.num_grid_points, r.summary.num_feasible_points, feasible_ratio, ...
        'VariableNames', {'slice_name', 'axis_1', 'axis_2', 'num_grid_points', 'num_feasible_points', 'feasible_ratio'});
end

summary_table = vertcat(rows{:});
end
