function out = build_dense_gap_surface_iP(full_theta_table_a, full_theta_table_b, label_a, label_b)
%BUILD_DENSE_GAP_SURFACE_IP Build a dense local minimum-requirement gap surface over (i, P).

if nargin < 3 || isempty(label_a)
    label_a = "heading";
end
if nargin < 4 || isempty(label_b)
    label_b = "nominal";
end

surface_a = build_mb_requirement_surface(full_theta_table_a, 'P', 'i_deg');
surface_b = build_mb_requirement_surface(full_theta_table_b, 'P', 'i_deg');
[gap_matrix, x_values, y_values] = local_build_gap_matrix(surface_a, surface_b);

out = struct();
out.label_a = string(label_a);
out.label_b = string(label_b);
out.surface_a = surface_a;
out.surface_b = surface_b;
out.x_values = x_values;
out.y_values = y_values;
out.gap_matrix = gap_matrix;
out.gap_table = local_gap_table(gap_matrix, x_values, y_values);
end

function [gap_matrix, x_values, y_values] = local_build_gap_matrix(surface_a, surface_b)
gap_matrix = [];
x_values = [];
y_values = [];
if isempty(surface_a) || isempty(surface_b) || isempty(surface_a.value_matrix) || isempty(surface_b.value_matrix)
    return;
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

function gap_table = local_gap_table(gap_matrix, x_values, y_values)
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
            'VariableNames', {'P', 'i_deg', 'minimum_requirement_gap'});
    end
end

rows = rows(1:row_count);
if ~isempty(rows)
    gap_table = vertcat(rows{:});
end
end
