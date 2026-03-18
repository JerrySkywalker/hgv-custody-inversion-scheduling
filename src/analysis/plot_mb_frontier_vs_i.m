function fig = plot_mb_frontier_vs_i(frontier_table, style)
%PLOT_MB_FRONTIER_VS_I Plot the minimum-feasible constellation frontier as a function of inclination.

if nargin < 2 || isempty(style)
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
title(ax, 'Inclination Frontier of Minimum Feasible Constellation Size');
grid(ax, 'on');
hold(ax, 'off');
end
