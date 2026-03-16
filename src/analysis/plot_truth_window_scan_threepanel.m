function fig = plot_truth_window_scan_threepanel(plot_data, style)
%PLOT_TRUTH_WINDOW_SCAN_THREEPANEL Plot DG/DA/DT_bar in three aligned panels.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
tl = tiledlayout(fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
title(tl, sprintf('基线真值窗口扫描: %s, T_w = %.0f s', char(plot_data.case_id), plot_data.Tw_s), ...
    'FontSize', style.title_font_size, 'FontWeight', 'bold', 'Interpreter', 'tex');

ax1 = nexttile;
plot(ax1, plot_data.t0_s, plot_data.DG, '-', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
yline(ax1, 1.0, style.threshold_line_style, '阈值 = 1', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color, 'Interpreter', 'tex');
ylabel(ax1, 'D_G', 'Interpreter', 'tex');

ax2 = nexttile;
plot(ax2, plot_data.t0_s, plot_data.DA, '--', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
yline(ax2, 1.0, style.threshold_line_style, '阈值 = 1', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color, 'Interpreter', 'tex');
ylabel(ax2, 'D_A', 'Interpreter', 'tex');

ax3 = nexttile;
plot(ax3, plot_data.t0_s, plot_data.DT_bar, ':', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
yline(ax3, 0.5, style.threshold_line_style, '阈值 = 0.5', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color, 'Interpreter', 'tex');
xlabel(ax3, '窗口起点 t_0 (s)', 'Interpreter', 'tex');
ylabel(ax3, '$\bar{D}_T$', 'Interpreter', 'latex');

annotation(fig, 'textbox', [0.61, 0.865, 0.30, 0.10], ...
    'String', sprintf('$D_G^{worst} = %.3f$\n$D_A^{worst} = %.3f$\n$\\bar{D}_T^{worst} = %.3f$', ...
        plot_data.DG_worst, plot_data.DA_worst, plot_data.DT_bar_worst), ...
    'Interpreter', 'latex', ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', 0.75 * [1, 1, 1], ...
    'FontSize', style.annotation_font_size);

apply_dissertation_plot_style(fig, style);
end
