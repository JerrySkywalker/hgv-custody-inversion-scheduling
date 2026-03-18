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
    cmin = min(surface.value_matrix(:), [], 'omitnan');
    cmax = max(surface.value_matrix(:), [], 'omitnan');
    if isfinite(cmin) && isfinite(cmax) && cmax > cmin
        clim(ax, [cmin, cmax]);
    end
    colormap(ax, parula);
    cb = colorbar(ax);
    cb.Label.String = 'Minimum feasible N_s';
    local_overlay_labels(ax, surface.x_values, surface.y_values, surface.value_matrix);
end

if nargin >= 2 && ~isempty(minimum_design_table)
    scatter(ax, minimum_design_table.P, minimum_design_table.i_deg, 120, 'p', ...
        'MarkerFaceColor', [1.0, 0.92, 0.15], 'MarkerEdgeColor', style.threshold_color, 'LineWidth', 1.1, ...
        'DisplayName', 'Joint minimum shell');
    legend(ax, 'Location', 'eastoutside', 'Box', style.legend_box);
end

xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, 'Minimum Feasible Constellation Requirement over (i, P)');
grid(ax, 'on');
hold(ax, 'off');
end

function local_overlay_labels(ax, x_values, y_values, value_matrix)
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        value = value_matrix(iy, ix);
        if isfinite(value)
            txt = sprintf('%d', round(value));
            color = [0.05, 0.05, 0.05];
        else
            txt = char(215);
            color = [0.45, 0.45, 0.45];
        end
        text(ax, x_values(ix), y_values(iy), txt, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', color);
    end
end
end
