function fig = plot_mb_fixed_h_requirement_heatmap_iP(surface, style, options)
%PLOT_MB_FIXED_H_REQUIREMENT_HEATMAP_IP Plot minimum feasible N_s over (i, P) at fixed height.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 3 || isempty(options)
    options = struct();
end

h_km = local_getfield_or(surface, 'h_km', NaN);
render_mode = local_resolve_render_mode(surface, options);

fig = create_managed_figure(local_getfield_or(options, 'runtime', struct()), 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if local_surface_is_empty(surface, render_mode)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('h = %.0f km', h_km), ...
        'plot_domain_source', "no_heatmap_cell", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
else
    x_values = local_getfield_or(surface, 'x_values', []);
    y_values = local_getfield_or(surface, 'y_values', []);
    if render_mode == "state_map"
        state_matrix = local_getfield_or(surface, 'state_matrix', []);
        state_labels = string(local_getfield_or(surface, 'state_labels', ["undefined / uncomputed", "evaluated infeasible", "boundary suspect", "defined internal", "refined/overcompute"]));
        if isempty(state_matrix)
            [state_matrix, state_labels] = build_mb_heatmap_state_matrix(surface, struct(), struct('x_values', x_values, 'y_values', y_values));
        end
        imagesc(ax, x_values, y_values, state_matrix);
        set(ax, 'YDir', 'normal');
        cmap = [ ...
            0.92 0.92 0.92; ...
            0.74 0.74 0.74; ...
            0.96 0.70 0.25; ...
            0.19 0.55 0.91; ...
            0.12 0.68 0.38];
        colormap(ax, cmap(1:numel(state_labels), :));
        clim(ax, [-0.5, numel(state_labels) - 0.5]);
        cb = colorbar(ax, 'Ticks', 0:(numel(state_labels) - 1), 'TickLabels', cellstr(state_labels));
        cb.Label.String = 'Heatmap state';
    else
        value_matrix = local_getfield_or(surface, 'numeric_requirement_matrix', local_getfield_or(surface, 'value_matrix', []));
        heat_img = imagesc(ax, x_values, y_values, value_matrix);
        set(ax, 'YDir', 'normal');
        set(ax, 'Color', [0.93 0.93 0.93]);
        if ~isempty(value_matrix)
            heat_img.AlphaData = isfinite(value_matrix);
        end
        cmin = min(value_matrix(:), [], 'omitnan');
        cmax = max(value_matrix(:), [], 'omitnan');
        if isfinite(cmin) && isfinite(cmax) && cmax > cmin
            clim(ax, [cmin, cmax]);
        end
        colormap(ax, parula);
        cb = colorbar(ax);
        cb.Label.String = 'Minimum feasible N_s';
        if local_resolve_annotation_mode(surface, render_mode) == "numeric_labels"
            local_overlay_numeric_labels(ax, x_values, y_values, value_matrix);
        end
    end
end

xlabel(ax, 'P');
ylabel(ax, 'i (deg)');
title(ax, sprintf('Minimum Feasible Constellation Requirement over (i, P) at h = %.0f km', h_km));
local_add_diagnostics(ax, local_getfield_or(options, 'boundary_hit_table', table()), local_getfield_or(options, 'domain_summary', ""), options);
grid(ax, 'on');
hold(ax, 'off');
end

function render_mode = local_resolve_render_mode(surface, options)
render_mode = string(local_getfield_or(options, 'heatmap_render_mode', "auto"));
if ismember(render_mode, ["state_map", "discrete_state"])
    render_mode = "state_map";
    return;
end
if ismember(render_mode, ["numeric_requirement", "continuous"])
    render_mode = "numeric_requirement";
    return;
end
render_mode = "numeric_requirement";
edge_table = local_getfield_or(options, 'heatmap_edge_table', table());
surface_table = local_getfield_or(surface, 'surface_table', table());
if istable(edge_table) && ~isempty(edge_table)
    sparse_pattern = any(logical(local_table_column(edge_table, 'right_edge_only_pattern'))) || ...
        any(logical(local_table_column(edge_table, 'top_edge_coverage_insufficient'))) || ...
        any(logical(local_table_column(edge_table, 'frontier_coverage_low')));
    if sparse_pattern
        render_mode = "state_map";
        return;
    end
end
if istable(surface_table) && ~isempty(surface_table) && ismember('minimum_feasible_Ns', surface_table.Properties.VariableNames)
    feasible_ratio = mean(isfinite(surface_table.minimum_feasible_Ns));
    if feasible_ratio <= 0.35
        render_mode = "state_map";
    end
end
end

function tf = local_surface_is_empty(surface, render_mode)
if isempty(surface)
    tf = true;
    return;
end
if render_mode == "state_map"
    state_matrix = local_getfield_or(surface, 'state_matrix', []);
    x_values = local_getfield_or(surface, 'x_values', []);
    y_values = local_getfield_or(surface, 'y_values', []);
    tf = isempty(state_matrix) || isempty(x_values) || isempty(y_values);
else
    value_matrix = local_getfield_or(surface, 'numeric_requirement_matrix', local_getfield_or(surface, 'value_matrix', []));
    tf = isempty(value_matrix) || ~any(isfinite(value_matrix(:)));
end
end

function annotation_mode = local_resolve_annotation_mode(surface, render_mode)
if render_mode == "state_map"
    annotation_mode = string(local_getfield_or(surface, 'annotation_mode_state', "state_only"));
else
    annotation_mode = string(local_getfield_or(surface, 'annotation_mode_numeric', "numeric_labels"));
end
end

function local_overlay_numeric_labels(ax, x_values, y_values, value_matrix)
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        value = value_matrix(iy, ix);
        if ~isfinite(value)
            continue;
        end
        txt = sprintf('%d', round(value));
        color = [0.05, 0.05, 0.05];
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
plot_domain_label = string(local_getfield_or(options, 'plot_domain_label', ""));
if strlength(plot_domain_label) > 0
    text_lines(end + 1, 1) = "plot-domain: " + plot_domain_label; %#ok<AGROW>
elseif strlength(string(domain_summary)) > 0
    text_lines(end + 1, 1) = string(domain_summary); %#ok<AGROW>
end
if istable(boundary_hit_table) && ~isempty(boundary_hit_table)
    if any(logical(local_table_column(boundary_hit_table, 'is_boundary_dominated')))
        text_lines(end + 1, 1) = "diag: boundary dominated"; %#ok<AGROW>
    end
    if any(logical(local_table_column(boundary_hit_table, 'search_upper_bound_likely_insufficient')))
        text_lines(end + 1, 1) = "diag: upper bound insufficient"; %#ok<AGROW>
    end
end
scope_annotation = string(local_getfield_or(options, 'scope_annotation_text', ""));
if strlength(scope_annotation) > 0
    text_lines(end + 1, 1) = scope_annotation; %#ok<AGROW>
end
if isempty(text_lines)
    return;
end
text(ax, 0.02, 0.98, char(strjoin(text_lines(1:min(end, 2)), newline)), ...
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
