function fig = plot_mb_requirement_heatmap_hi(surface, minimum_design_table, style)
%PLOT_MB_REQUIREMENT_HEATMAP_HI Plot minimum feasible constellation size over the (i, h) plane.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(surface) || isempty(surface.value_matrix)
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
else
    imagesc(ax, surface.x_values, surface.y_values, surface.value_matrix);
    set(ax, 'YDir', 'normal');
    alpha_data = ~isnan(surface.value_matrix);
    set(get(ax, 'Children'), 'AlphaData', alpha_data);
    colormap(ax, parula);
    cb = colorbar(ax);
    cb.Label.String = 'Minimum feasible N_s';
end

if nargin >= 2 && ~isempty(minimum_design_table)
    scatter(ax, minimum_design_table.i_deg, minimum_design_table.h_km, 110, 'p', ...
        'MarkerFaceColor', [1.0, 0.92, 0.15], 'MarkerEdgeColor', style.threshold_color, 'LineWidth', 1.1);
end

xlabel(ax, 'i (deg)');
ylabel(ax, 'h (km)');
title(ax, 'Minimum Constellation Requirement over (h, i)');
grid(ax, 'on');
hold(ax, 'off');
end
