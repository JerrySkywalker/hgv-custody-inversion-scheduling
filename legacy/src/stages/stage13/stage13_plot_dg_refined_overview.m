function fig_path = stage13_plot_dg_refined_overview(ranked_summary, paths)
%STAGE13_PLOT_DG_REFINED_OVERVIEW Plot DG refined family overview with recommendation highlight.

style = milestone_common_plot_style();
rows = ranked_summary;
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 90 1100 460]);
ax = axes(fig);
hold(ax, 'on');

x = 1:height(rows);
plot(ax, x, rows.D_G_worst, 'o-', 'LineWidth', 1.7, 'Color', style.colors(1, :), 'DisplayName', 'D_G^{worst}');
plot(ax, x, rows.D_A_worst, 's-', 'LineWidth', 1.7, 'Color', style.colors(2, :), 'DisplayName', 'D_A^{worst}');
plot(ax, x, rows.D_T_worst, 'd-', 'LineWidth', 1.7, 'Color', style.colors(3, :), 'DisplayName', 'D_T^{worst}');
yline(ax, 1, ':', 'Color', style.threshold_color, 'LineWidth', 1.2, 'DisplayName', 'threshold');

rec_idx = find(rows.recommendation_flag);
if ~isempty(rec_idx)
    scatter(ax, x(rec_idx), rows.D_G_worst(rec_idx), 96, style.colors(1, :), 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'recommended DG-min');
end

xticks(ax, x);
xticklabels(ax, cellstr(rows.case_tag));
xtickangle(ax, 25);
xlabel(ax, 'refined candidate', 'Interpreter', 'tex');
ylabel(ax, 'worst margin', 'Interpreter', 'tex');
title(ax, 'Stage13.6 DG-refined family overview', 'Interpreter', 'tex');
legend(ax, 'Location', 'best', 'Interpreter', 'tex');
grid(ax, 'on');
apply_dissertation_plot_style(fig, style);

fig_path = fullfile(paths.figures, 'stage13_family_overview_dg_refined.png');
milestone_common_save_figure(fig, fig_path);
close(fig);
fig_path = string(fig_path);
end
