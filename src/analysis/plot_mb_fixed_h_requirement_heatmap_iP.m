function fig = plot_mb_fixed_h_requirement_heatmap_iP(surface, style)
%PLOT_MB_FIXED_H_REQUIREMENT_HEATMAP_IP Plot minimum feasible N_s over (i, P) at fixed height.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

h_km = local_getfield_or(surface, 'h_km', NaN);

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(surface) || ~isfield(surface, 'value_matrix') || isempty(surface.value_matrix)
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

xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, sprintf('Minimum Feasible Constellation Requirement over (i, P) at h = %.0f km', h_km));
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

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
