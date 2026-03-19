function fig = plot_semantic_gap_heatmap(gap_table, h_km, sensor_label)
%PLOT_SEMANTIC_GAP_HEATMAP Plot Delta N_s = closedD - legacyDG over (i, P).

if nargin < 3
    sensor_label = "";
end

P_values = unique(gap_table.P, 'sorted');
i_values = unique(gap_table.i_deg, 'sorted');
value_matrix = NaN(numel(i_values), numel(P_values));
for iy = 1:numel(i_values)
    for ix = 1:numel(P_values)
        hit = gap_table.i_deg == i_values(iy) & gap_table.P == P_values(ix);
        if any(hit)
            value_matrix(iy, ix) = gap_table.delta_Ns(find(hit, 1, 'first'));
        end
    end
end

finite_values = value_matrix(isfinite(value_matrix));
display_matrix = value_matrix;
display_matrix(~isfinite(display_matrix)) = NaN;

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');
imagesc(ax, P_values, i_values, display_matrix);
set(ax, 'YDir', 'normal');
if ~isempty(finite_values)
    clim(ax, [min(finite_values), max(finite_values)]);
end
colormap(ax, parula);
cb = colorbar(ax);
cb.Label.String = '\Delta N_s = closedD - legacyDG';
local_overlay_labels(ax, P_values, i_values, value_matrix);

xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, sprintf('Semantic Gap Heatmap over (i, P) at h = %.0f km [%s]', h_km, char(string(sensor_label))));
grid(ax, 'on');
hold(ax, 'off');
end

function local_overlay_labels(ax, x_values, y_values, value_matrix)
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        value = value_matrix(iy, ix);
        if isfinite(value)
            txt = sprintf('%d', round(value));
            color = [0.1, 0.1, 0.1];
        elseif isinf(value) && value > 0
            txt = '+inf';
            color = [0.75, 0.15, 0.15];
        elseif isinf(value) && value < 0
            txt = '-inf';
            color = [0.15, 0.25, 0.75];
        else
            txt = char(215);
            color = [0.45, 0.45, 0.45];
        end
        text(ax, x_values(ix), y_values(iy), txt, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'Color', color);
    end
end
end
