function fig = plot_milestone_B_task_slice_compare(task_summary_table, style)
%PLOT_MILESTONE_B_TASK_SLICE_COMPARE Plot task-family feasible ratio comparison.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);

if isempty(task_summary_table)
    bar(ax, categorical("no_data"), 0, 'FaceColor', style.colors(1, :));
    title(ax, 'Milestone B Task-Side Slice Comparison');
    ylabel(ax, 'Feasible ratio');
    grid(ax, 'on');
    return;
end

bar(ax, categorical(string(task_summary_table.task_slice_id)), task_summary_table.feasible_ratio, ...
    'FaceColor', style.colors(2, :));
ylabel(ax, 'Feasible ratio');
title(ax, 'Milestone B Task-Side Slice Comparison');
grid(ax, 'on');
end
