function fig = plot_truth_window_scan_threepanel(plot_data, style)
%PLOT_TRUTH_WINDOW_SCAN_THREEPANEL Plot DG/DA/DT_bar in three aligned panels.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
plot(ax1, plot_data.t0_s, plot_data.DG, '-', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
yline(ax1, 1.0, style.threshold_line_style, '阈值 = 1', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color);
ylabel(ax1, 'D_G');
title(ax1, sprintf('基线真值窗口扫描: %s, T_w = %.0f s', plot_data.case_id, plot_data.Tw_s));
grid(ax1, 'on');

ax2 = nexttile;
plot(ax2, plot_data.t0_s, plot_data.DA, '--', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
yline(ax2, 1.0, style.threshold_line_style, '阈值 = 1', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color);
ylabel(ax2, 'D_A');
grid(ax2, 'on');

ax3 = nexttile;
plot(ax3, plot_data.t0_s, plot_data.DT_bar, ':', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
yline(ax3, 0.5, style.threshold_line_style, '阈值 = 0.5', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color);
xlabel(ax3, '窗口起点 t_0 (s)');
ylabel(ax3, '\bar{D}_T');
title(ax3, '时序面板使用有界时序连续性裕度 \bar{D}_T；闭合判定对应 D_T >= 1');
grid(ax3, 'on');
end
