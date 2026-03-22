function fig = plot_mb_fixed_h_requirement_heatmap_iP(surface, style, options)
%PLOT_MB_FIXED_H_REQUIREMENT_HEATMAP_IP Plot minimum feasible N_s over (i, P) at fixed height.

if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 3 || isempty(options)
    options = struct();
end

h_km = local_getfield_or(surface, 'h_km', NaN);

fig = create_managed_figure(local_getfield_or(options, 'runtime', struct()), 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(surface) || ~isfield(surface, 'value_matrix') || isempty(surface.value_matrix) || ~any(isfinite(surface.value_matrix(:)))
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('h = %.0f km', h_km), ...
        'plot_domain_source', "no_heatmap_cell", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
else
    render_mode = local_resolve_render_mode(surface, options);
    if render_mode == "discrete_state"
        [state_matrix, state_labels] = local_build_state_matrix(surface, local_getfield_or(options, 'search_domain_bounds', []));
        imagesc(ax, surface.x_values, surface.y_values, state_matrix);
        set(ax, 'YDir', 'normal');
        colormap(ax, [0.92 0.92 0.92; 0.96 0.70 0.25; 0.19 0.55 0.91; 0.12 0.68 0.38]);
        clim(ax, [-0.5, 3.5]);
        cb = colorbar(ax, 'Ticks', 0:3, 'TickLabels', cellstr(state_labels));
        cb.Label.String = 'Heatmap state';
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
if render_mode == "discrete_state" || render_mode == "continuous"
    return;
end
render_mode = "continuous";
edge_table = local_getfield_or(options, 'heatmap_edge_table', table());
surface_table = local_getfield_or(surface, 'surface_table', table());
if istable(edge_table) && ~isempty(edge_table)
    sparse_pattern = any(logical(local_table_column(edge_table, 'right_edge_only_pattern'))) || ...
        any(logical(local_table_column(edge_table, 'top_edge_coverage_insufficient'))) || ...
        any(logical(local_table_column(edge_table, 'frontier_coverage_low')));
    if sparse_pattern
        render_mode = "discrete_state";
        return;
    end
end
if istable(surface_table) && ~isempty(surface_table) && ismember('minimum_feasible_Ns', surface_table.Properties.VariableNames)
    feasible_ratio = mean(isfinite(surface_table.minimum_feasible_Ns));
    if feasible_ratio <= 0.35
        render_mode = "discrete_state";
    end
end
end

function [state_matrix, state_labels] = local_build_state_matrix(surface, search_domain_bounds)
x_values = surface.x_values;
y_values = surface.y_values;
value_matrix = surface.value_matrix;
state_matrix = zeros(size(value_matrix));
state_matrix(~isfinite(value_matrix)) = 0;
state_matrix(isfinite(value_matrix)) = 2;
state_labels = ["undefined", "boundary suspect", "defined internal", "refined/overcompute"];

ns_max = NaN;
if isnumeric(search_domain_bounds) && numel(search_domain_bounds) == 2
    ns_max = max(search_domain_bounds);
end
tol = max(4, 0.03 * max(1, ns_max));
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        if ~isfinite(value_matrix(iy, ix))
            continue;
        end
        if ix == numel(x_values) || (isfinite(ns_max) && value_matrix(iy, ix) >= ns_max - tol)
            state_matrix(iy, ix) = 1;
        end
    end
end

surface_table = local_getfield_or(surface, 'surface_table', table());
if istable(surface_table) && ~isempty(surface_table)
    for idx = 1:height(surface_table)
        p_idx = find(abs(x_values - surface_table.P(idx)) < 1.0e-9, 1, 'first');
        i_idx = find(abs(y_values - surface_table.i_deg(idx)) < 1.0e-9, 1, 'first');
        if isempty(p_idx) || isempty(i_idx)
            continue;
        end
        touched = false;
        if ismember('aesthetic_overcompute_touched', surface_table.Properties.VariableNames)
            touched = touched || logical(surface_table.aesthetic_overcompute_touched(idx));
        end
        if ismember('frontier_refinement_touched', surface_table.Properties.VariableNames)
            touched = touched || logical(surface_table.frontier_refinement_touched(idx));
        end
        if touched && isfinite(value_matrix(i_idx, p_idx))
            state_matrix(i_idx, p_idx) = 3;
        end
    end
end
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
