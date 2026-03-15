function fig = plot_milestone_A_truth_scan(plot_data, style, mode)
%PLOT_MILESTONE_A_TRUTH_SCAN Plot dissertation-facing truth scan for Milestone A.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 3 || isempty(mode)
    mode = 'main';
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);

plot(ax, plot_data.t0_s, plot_data.DG, '-', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
hold(ax, 'on');
plot(ax, plot_data.t0_s, plot_data.DA, '--', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
plot(ax, plot_data.t0_s, plot_data.DT, ':', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
yline(ax, 1.0, style.threshold_line_style, 'Threshold', ...
    'LineWidth', style.threshold_line_width, 'Color', style.threshold_color, ...
    'LabelHorizontalAlignment', 'left');

if strcmpi(mode, 'highlight')
    xline(ax, plot_data.t0G_star_s, '-', 't0G*', 'Color', style.colors(1, :), 'LineWidth', style.marker_line_width);
    xline(ax, plot_data.t0A_star_s, '--', 't0A*', 'Color', style.colors(2, :), 'LineWidth', style.marker_line_width);
    xline(ax, plot_data.t0T_star_s, ':', 't0T*', 'Color', style.colors(3, :), 'LineWidth', style.marker_line_width);
else
    plot(ax, plot_data.t0G_star_s, min(plot_data.DG), style.worst_marker, ...
        'MarkerSize', style.marker_size + 1, 'MarkerFaceColor', style.colors(1, :), 'Color', style.colors(1, :));
    plot(ax, plot_data.t0A_star_s, min(plot_data.DA), style.worst_marker, ...
        'MarkerSize', style.marker_size + 1, 'MarkerFaceColor', style.colors(2, :), 'Color', style.colors(2, :));
    plot(ax, plot_data.t0T_star_s, min(plot_data.DT), style.worst_marker, ...
        'MarkerSize', style.marker_size + 1, 'MarkerFaceColor', style.colors(3, :), 'Color', style.colors(3, :));
end

xlabel(ax, 'Window start t_0 (s)');
ylabel(ax, 'Truth metric value');
title(ax, sprintf('Milestone A Truth Window Scan: %s', plot_data.case_id));
legend(ax, {'DG(t_0)', 'DA(t_0)', 'DT(t_0)', 'Threshold'}, 'Location', 'best');
grid(ax, 'on');
hold(ax, 'off');
end
