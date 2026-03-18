function fig = plot_mb_fixed_h_frontier_vs_i(frontier_table, h_km, style)
%PLOT_MB_FIXED_H_FRONTIER_VS_I Plot the fixed-height minimum-feasible inclination frontier.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(frontier_table)
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
else
    plot(ax, frontier_table.i_deg, frontier_table.minimum_feasible_Ns, '-o', ...
        'Color', style.colors(1, :), ...
        'LineWidth', style.line_width, ...
        'MarkerSize', style.marker_size + 1, ...
        'MarkerFaceColor', style.colors(1, :));
    for idx = 1:height(frontier_table)
        text(ax, frontier_table.i_deg(idx), frontier_table.minimum_feasible_Ns(idx) + 0.8, ...
            sprintf('%d', round(frontier_table.minimum_feasible_Ns(idx))), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', style.threshold_color);
    end
end

xlabel(ax, 'i (deg)');
ylabel(ax, 'Minimum feasible N_s');
title(ax, sprintf('Inclination Frontier of Minimum Feasible Constellation Size at h = %.0f km', h_km));
grid(ax, 'on');
hold(ax, 'off');
end
