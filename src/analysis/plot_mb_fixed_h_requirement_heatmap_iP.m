function fig = plot_mb_fixed_h_requirement_heatmap_iP(surface, style, options)
%PLOT_MB_FIXED_H_REQUIREMENT_HEATMAP_IP Plot minimum feasible N_s over (i, P) at fixed height.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 3 || isempty(options)
    options = struct();
end

h_km = local_getfield_or(surface, 'h_km', NaN);

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(surface) || ~isfield(surface, 'value_matrix') || isempty(surface.value_matrix) || ~any(isfinite(surface.value_matrix(:)))
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('h = %.0f km', h_km), ...
        'plot_domain_source', "no_heatmap_cell", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
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
local_add_diagnostics(ax, local_getfield_or(options, 'boundary_hit_table', table()), local_getfield_or(options, 'domain_summary', ""), options);
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

function local_add_diagnostics(ax, boundary_hit_table, domain_summary, options)
if ~local_show_annotations(options)
    return;
end
text_lines = strings(0, 1);
if strlength(string(domain_summary)) > 0
    text_lines(end + 1, 1) = string(domain_summary); %#ok<AGROW>
end
if istable(boundary_hit_table) && ~isempty(boundary_hit_table)
    if any(logical(local_table_column(boundary_hit_table, 'is_boundary_dominated')))
        text_lines(end + 1, 1) = "boundary-dominated result"; %#ok<AGROW>
    end
    if any(logical(local_table_column(boundary_hit_table, 'search_upper_bound_likely_insufficient')))
        text_lines(end + 1, 1) = "search upper bound likely insufficient"; %#ok<AGROW>
    end
end
if isempty(text_lines)
    return;
end
text(ax, 0.02, 0.98, char(strjoin(text_lines, newline)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontSize', 9.5, 'Color', [0.55 0.15 0.15]);
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
