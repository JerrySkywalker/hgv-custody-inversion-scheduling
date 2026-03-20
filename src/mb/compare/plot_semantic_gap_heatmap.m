function fig = plot_semantic_gap_heatmap(gap_table, h_km, sensor_label, options)
%PLOT_SEMANTIC_GAP_HEATMAP Plot Delta N_s = closedD - legacyDG over (i, P).

if nargin < 3
    sensor_label = "";
end
if nargin < 4 || isempty(options)
    options = struct();
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
setappdata(fig, 'mb_figure_style', local_getfield_or(options, 'figure_style', struct()));
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
local_add_diagnostics(ax, local_getfield_or(options, 'boundary_hit_table', table()), options);
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

function local_add_diagnostics(ax, boundary_hit_table, options)
if ~local_show_annotations(options)
    return;
end
if isempty(boundary_hit_table) || ~istable(boundary_hit_table)
    return;
end
note_lines = strings(0, 1);
if any(logical(local_table_column(boundary_hit_table, 'is_boundary_dominated')))
    note_lines(end + 1, 1) = "boundary-dominated result"; %#ok<AGROW>
end
if any(logical(local_table_column(boundary_hit_table, 'search_upper_bound_likely_insufficient')))
    note_lines(end + 1, 1) = "search upper bound likely insufficient"; %#ok<AGROW>
end
if isempty(note_lines)
    return;
end
text(ax, 0.02, 0.98, strjoin(cellstr(note_lines), newline), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', 10, ...
    'Color', [0.55 0.15 0.15], 'FontWeight', 'bold');
end

function tf = local_show_annotations(options)
style_mode = local_getfield_or(options, 'figure_style', struct());
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation')
    tf = logical(style_mode.show_diagnostic_annotation);
else
    tf = true;
end
end

function values = local_table_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
