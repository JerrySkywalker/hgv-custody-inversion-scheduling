function [fig, gap_table] = plot_mb_dense_gap_heatmap_heading_minus_nominal(gap_surface, style)
%PLOT_MB_DENSE_GAP_HEATMAP_HEADING_MINUS_NOMINAL Plot local zoom heading-nominal requirement gap.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

gap_table = gap_surface.gap_table;
fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');
if isempty(gap_surface.gap_matrix)
    plot(ax, 0, 0, 'o', 'Color', style.colors(2, :));
else
    imagesc(ax, gap_surface.x_values, gap_surface.y_values, gap_surface.gap_matrix);
    set(ax, 'YDir', 'normal');
    colormap(ax, turbo);
    gap_abs = max(abs(gap_surface.gap_matrix(:)), [], 'omitnan');
    if isfinite(gap_abs) && gap_abs > 0
        clim(ax, [-gap_abs, gap_abs]);
    end
    cb = colorbar(ax);
    cb.Label.String = 'Minimum N_s gap (heading - nominal)';
    local_overlay_gap_labels(ax, gap_surface.x_values, gap_surface.y_values, gap_surface.gap_matrix);
end
xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, 'Local Zoom Incremental Requirement Gap: heading - nominal');
grid(ax, 'on');
hold(ax, 'off');
end

function local_overlay_gap_labels(ax, x_values, y_values, gap_matrix)
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        value = gap_matrix(iy, ix);
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
            'FontWeight', 'bold', ...
            'FontSize', 10, ...
            'Color', color);
    end
end
end
