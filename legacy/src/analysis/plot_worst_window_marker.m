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
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color, 'Interpreter', 'tex');
yline(ax, 0.5, ':', '$\bar{D}_T$ 阈值 = 0.5', ...
    'LineWidth', style.threshold_line_width, 'Color', style.colors(3, :), 'Interpreter', 'latex');

same_marker = (plot_data.t0G_star_s == plot_data.t0A_star_s) && (plot_data.t0A_star_s == plot_data.t0T_star_s);
if same_marker
    xline(ax, plot_data.t0G_star_s, '-', '', 'LineWidth', style.marker_line_width, ...
        'Color', style.threshold_color);
    text(ax, plot_data.t0G_star_s, max([plot_data.DG; plot_data.DA; plot_data.DT_bar]) * 0.96, ...
        sprintf('共同最坏窗口: t_0^* = %.0f s', plot_data.t0G_star_s), ...
        'Interpreter', 'tex', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'BackgroundColor', 'w', ...
        'Margin', 4);
else
    xline(ax, plot_data.t0G_star_s, '-', 't_{0,G}^*', 'Color', style.colors(1, :), 'LineWidth', style.marker_line_width, 'Interpreter', 'tex');
    xline(ax, plot_data.t0A_star_s, '--', 't_{0,A}^*', 'Color', style.colors(2, :), 'LineWidth', style.marker_line_width, 'Interpreter', 'tex');
    xline(ax, plot_data.t0T_star_s, ':', 't_{0,T}^*', 'Color', style.colors(3, :), 'LineWidth', style.marker_line_width, 'Interpreter', 'tex');
end

xlabel(ax, '窗口起点 t_0 (s)', 'Interpreter', 'tex');
ylabel(ax, '裕度曲线', 'Interpreter', 'tex');
title(ax, sprintf('最坏窗口定位: %s', char(plot_data.case_id)), 'Interpreter', 'tex', 'FontSize', style.title_font_size);
legend(ax, {'$D_G$', '$D_A$', '$\bar{D}_T$'}, 'Location', 'best', 'Interpreter', 'latex');
hold(ax, 'off');
apply_dissertation_plot_style(fig, style);
end
