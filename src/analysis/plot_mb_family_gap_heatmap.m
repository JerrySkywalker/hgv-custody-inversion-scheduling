function [fig, gap_table] = plot_mb_family_gap_heatmap(surface_a, surface_b, label_a, label_b, style)
%PLOT_MB_FAMILY_GAP_HEATMAP Plot the minimum-requirement gap between two family surfaces.

if nargin < 3 || isempty(label_a)
    label_a = "A";
end
if nargin < 4 || isempty(label_b)
    label_b = "B";
end
if nargin < 5 || isempty(style)
    style = milestone_common_plot_style();
end

[gap_matrix, x_values, y_values] = local_build_gap_matrix(surface_a, surface_b);
gap_table = local_gap_table(gap_matrix, x_values, y_values, surface_a);

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');
if isempty(gap_matrix)
    plot(ax, 0, 0, 'o', 'Color', style.colors(2, :));
else
    imagesc(ax, x_values, y_values, gap_matrix);
    set(ax, 'YDir', 'normal');
    alpha_data = ~isnan(gap_matrix);
    set(get(ax, 'Children'), 'AlphaData', alpha_data);
    colormap(ax, turbo);
    cb = colorbar(ax);
    cb.Label.String = sprintf('Minimum N_s gap (%s - %s)', char(string(label_a)), char(string(label_b)));
end
xlabel(ax, local_axis_label(surface_a.xvar));
ylabel(ax, local_axis_label(surface_a.yvar));
title(ax, sprintf('Requirement Gap Heatmap: %s - %s', char(string(label_a)), char(string(label_b))));
grid(ax, 'on');
hold(ax, 'off');
end

function [gap_matrix, x_values, y_values] = local_build_gap_matrix(surface_a, surface_b)
gap_matrix = [];
x_values = [];
y_values = [];
if isempty(surface_a) || isempty(surface_b) || isempty(surface_a.value_matrix) || isempty(surface_b.value_matrix)
    return;
end

if ~strcmpi(char(surface_a.xvar), char(surface_b.xvar)) || ~strcmpi(char(surface_a.yvar), char(surface_b.yvar))
    error('surface_a and surface_b must use the same axes.');
end

x_values = unique([surface_a.x_values(:); surface_b.x_values(:)], 'sorted');
y_values = unique([surface_a.y_values(:); surface_b.y_values(:)], 'sorted');
gap_matrix = nan(numel(y_values), numel(x_values));

for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        a = local_lookup_surface_value(surface_a, x_values(ix), y_values(iy));
        b = local_lookup_surface_value(surface_b, x_values(ix), y_values(iy));
        if isfinite(a) && isfinite(b)
            gap_matrix(iy, ix) = a - b;
        end
    end
end
end

function value = local_lookup_surface_value(surface, x_value, y_value)
value = NaN;
ix = find(surface.x_values == x_value, 1, 'first');
iy = find(surface.y_values == y_value, 1, 'first');
if isempty(ix) || isempty(iy)
    return;
end
value = surface.value_matrix(iy, ix);
end

function gap_table = local_gap_table(gap_matrix, x_values, y_values, surface)
gap_table = table();
if isempty(gap_matrix)
    return;
end

rows = cell(numel(x_values) * numel(y_values), 1);
row_count = 0;
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        if ~isfinite(gap_matrix(iy, ix))
            continue;
        end
        row_count = row_count + 1;
        rows{row_count} = table(x_values(ix), y_values(iy), gap_matrix(iy, ix), ...
            'VariableNames', {char(surface.xvar), char(surface.yvar), 'minimum_requirement_gap'});
    end
end
rows = rows(1:row_count);
if ~isempty(rows)
    gap_table = vertcat(rows{:});
end
end

function txt = local_axis_label(name)
switch char(string(name))
    case 'i_deg'
        txt = 'i (deg)';
    case 'h_km'
        txt = 'h (km)';
    otherwise
        txt = char(string(name));
end
end
