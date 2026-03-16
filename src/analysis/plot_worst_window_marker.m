function fig = plot_worst_window_marker(plot_data, style)
%PLOT_WORST_WINDOW_MARKER Plot worst-window markers with overlap handling.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
plot(ax, plot_data.t0_s, plot_data.DG, '-', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
hold(ax, 'on');
plot(ax, plot_data.t0_s, plot_data.DA, '--', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
plot(ax, plot_data.t0_s, plot_data.DT_bar, ':', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
yline(ax, 1.0, style.threshold_line_style, 'D_G / D_A 阈值 = 1', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color);

same_marker = (plot_data.t0G_star_s == plot_data.t0A_star_s) && (plot_data.t0A_star_s == plot_data.t0T_star_s);
if same_marker
    xline(ax, plot_data.t0G_star_s, '-', '共同最坏窗口', 'LineWidth', style.marker_line_width, ...
        'Color', style.threshold_color, 'LabelVerticalAlignment', 'bottom');
else
    xline(ax, plot_data.t0G_star_s, '-', 't0G*', 'Color', style.colors(1, :), 'LineWidth', style.marker_line_width);
    xline(ax, plot_data.t0A_star_s, '--', 't0A*', 'Color', style.colors(2, :), 'LineWidth', style.marker_line_width);
    xline(ax, plot_data.t0T_star_s, ':', 't0T*', 'Color', style.colors(3, :), 'LineWidth', style.marker_line_width);
end

xlabel(ax, '窗口起点 t_0 (s)');
ylabel(ax, '标准化 / 有界裕度');
title(ax, sprintf('最坏窗口定位: %s', plot_data.case_id));
legend(ax, {'D_G', 'D_A', '\bar{D}_T'}, 'Location', 'best');
grid(ax, 'on');
hold(ax, 'off');
end
