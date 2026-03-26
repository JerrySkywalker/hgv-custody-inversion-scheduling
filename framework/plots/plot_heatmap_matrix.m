function fig = plot_heatmap_matrix(row_values, col_values, value_matrix, plot_spec)
%PLOT_HEATMAP_MATRIX Minimal heatmap plotting helper.

if nargin < 4
    plot_spec = struct();
end

title_text = local_get(plot_spec, 'title', '');
x_label = local_get(plot_spec, 'x_label', 'T');
y_label = local_get(plot_spec, 'y_label', 'P');
show_colorbar = local_get(plot_spec, 'show_colorbar', true);
visible_mode = local_get(plot_spec, 'visible', 'on');

fig = figure('Visible', visible_mode);
imagesc(col_values, row_values, value_matrix);
set(gca, 'YDir', 'normal');
xlabel(x_label);
ylabel(y_label);
title(title_text);

if show_colorbar
    colorbar;
end
end

function v = local_get(s, f, d)
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end
end
