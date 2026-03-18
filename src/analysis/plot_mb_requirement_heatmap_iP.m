function fig = plot_mb_requirement_heatmap_iP(surface, minimum_design_table, style)
%PLOT_MB_REQUIREMENT_HEATMAP_IP Plot minimum feasible constellation size over the (i, P) plane.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(surface) || isempty(surface.value_matrix)
    plot(ax, 0, 0, 'o', 'Color', style.colors(2, :));
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
    scatter(ax, minimum_design_table.P, minimum_design_table.i_deg, 110, 'p', ...
        'MarkerFaceColor', [1.0, 0.92, 0.15], 'MarkerEdgeColor', style.threshold_color, 'LineWidth', 1.1);
end

xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, 'Minimum Constellation Requirement over (i, P)');
grid(ax, 'on');
hold(ax, 'off');
end
