function fig = plot_mb_task_family_comparison(task_summary_table, style)
%PLOT_MB_TASK_FAMILY_COMPARISON Plot task-family comparison for Milestone B.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

families = categorical("no_data");
if ~isempty(task_summary_table)
    families = categorical(string(task_summary_table.family_name));
end

ax1 = nexttile;
if isempty(task_summary_table)
    bar(ax1, families, 0, 'FaceColor', style.colors(2, :));
else
    bar(ax1, families, task_summary_table.feasible_ratio, 'FaceColor', style.colors(2, :));
end
ylabel(ax1, 'Feasible ratio');
title(ax1, 'Milestone B Task Feasible Ratio');
grid(ax1, 'on');

ax2 = nexttile;
if isempty(task_summary_table)
    bar(ax2, families, 0, 'FaceColor', style.colors(3, :));
else
    values = task_summary_table.Ns_min_feasible;
    values(~isfinite(values)) = 0;
    bar(ax2, families, values, 'FaceColor', style.colors(3, :));
end
ylabel(ax2, 'Minimum feasible N_s');
title(ax2, 'Task-Family Minimum Design Size');
grid(ax2, 'on');

ax3 = nexttile;
if isempty(task_summary_table)
    bar(ax3, families, 0, 'FaceColor', style.threshold_color);
else
    values = task_summary_table.best_joint_margin;
    values(~isfinite(values)) = 0;
    bar(ax3, families, values, 'FaceColor', style.threshold_color);
end
ylabel(ax3, 'Best joint margin');
title(ax3, 'Task-Family Best Margin');
grid(ax2, 'on');
grid(ax3, 'on');
end
