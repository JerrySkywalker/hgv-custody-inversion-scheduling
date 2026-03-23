function fig = plot_semantic_gap_passratio_curves(gap_table, h_km, sensor_label, options)
%PLOT_SEMANTIC_GAP_PASSRATIO_CURVES Plot overlay and gap curves for pass ratio.

if nargin < 3
    sensor_label = "";
end
if nargin < 4 || isempty(options)
    options = struct();
end

i_values = unique(local_getfield_or(gap_table, 'i_deg', []), 'sorted');
cmap = turbo(max(2, numel(i_values)));
guard = compute_mb_plot_window_from_data(local_getfield_or(gap_table, 'Ns', []), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'search_domain_bounds', local_getfield_or(options, 'search_domain_bounds', []), ...
    'empty_message', 'No valid pass-ratio comparison point found within current search domain'));

fig = create_managed_figure(local_getfield_or(options, 'runtime', struct()), 'Color', 'w');
setappdata(fig, 'mb_figure_style', local_getfield_or(options, 'figure_style', struct()));
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tiled, sprintf('Comparison Pass-Ratio Diagnostics at h = %.0f km [%s]', h_km, char(string(sensor_label))));
contract = local_getfield_or(options, 'plot_view_contract', struct());
base_grid_step = local_resolve_base_grid_step(gap_table);
gap_steps_for_break = max(1, double(local_getfield_or(options, 'passratio_gap_steps_for_break', 1)));
max_gap_for_connect = inf;
if isstruct(contract) && isfield(contract, 'view_name') && string(contract.view_name) ~= "historyFull" && isfinite(base_grid_step)
    max_gap_for_connect = gap_steps_for_break * base_grid_step;
end

ax1 = nexttile(tiled, 1);
hold(ax1, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    local_plot_curve(ax1, Ti.Ns, Ti.max_pass_ratio_legacyDG, local_pick_logical(Ti, 'legacy_present'), '--s', cmap(idx, :), 1.5, 5, sprintf('legacyDG i=%g', i_values(idx)), max_gap_for_connect);
    local_plot_curve(ax1, Ti.Ns, Ti.max_pass_ratio_closedD, local_pick_logical(Ti, 'closed_present'), '-o', cmap(idx, :), 1.8, 5, sprintf('closedD i=%g', i_values(idx)), max_gap_for_connect);
end
ylabel(ax1, 'max pass ratio');
title(ax1, 'Upper panel: pass ratio overlay');
grid(ax1, 'on');
apply_mb_plot_domain_guardrail(ax1, local_getfield_or(gap_table, 'Ns', []), local_getfield_or(gap_table, 'max_pass_ratio_closedD', []), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'ylim', [0, 1.05], ...
    'search_domain_bounds', local_getfield_or(options, 'search_domain_bounds', []), ...
    'empty_message', 'No valid pass-ratio comparison point found within current search domain', ...
    'domain_summary', sprintf('h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
    'plot_domain_source', guard.plot_domain_source, ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
if local_show_annotations(options)
    text(ax1, 0.02, 0.96, char("plot-domain: " + string(local_getfield_or(options, 'plot_domain_label', "expanded_final_shared"))), ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.20 0.20 0.20], 'VerticalAlignment', 'top');
    scope_text = string(local_getfield_or(options, 'scope_annotation_text', ""));
    if strlength(scope_text) > 0
        text(ax1, 0.02, 0.88, char(scope_text), ...
            'Units', 'normalized', 'FontSize', 10, 'Color', [0.20 0.20 0.20], 'VerticalAlignment', 'top');
    end
end

[legacy_plateau, closed_plateau, plateau_note] = local_plateau_status(gap_table, local_getfield_or(options, 'passratio_saturation_table', table()));
if local_show_annotations(options) && strlength(plateau_note) > 0
    text(ax1, 0.02, 0.84, 'status: plateau not reached', ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.55 0.15 0.15], 'VerticalAlignment', 'top');
end

ax2 = nexttile(tiled, 2);
hold(ax2, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    local_plot_curve(ax2, Ti.Ns, Ti.passratio_gap, isfinite(Ti.passratio_gap), '-o', cmap(idx, :), 1.6, 5, sprintf('gap i=%g', i_values(idx)), max_gap_for_connect);
end
yline(ax2, 0, ':', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.1);
xlabel(ax2, 'N_s');
ylabel(ax2, '\Delta pass ratio');
title(ax2, 'Lower panel: \Delta pass ratio (closedD - legacyDG)');
if local_show_annotations(options)
    text(ax2, 0.02, 0.92, 'status: negative gap => closedD stricter', ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.25 0.25 0.25], ...
        'VerticalAlignment', 'top');
end
if local_show_annotations(options) && ~(legacy_plateau && closed_plateau)
    text(ax2, 0.02, 0.82, 'status: unsaturated domain', ...
        'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.55 0.15 0.15], ...
        'VerticalAlignment', 'top');
end
local_add_boundary_note(ax2, local_getfield_or(options, 'boundary_hit_table', table()), options);
apply_mb_plot_domain_guardrail(ax2, local_getfield_or(gap_table, 'Ns', []), local_getfield_or(gap_table, 'passratio_gap', []), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'search_domain_bounds', local_getfield_or(options, 'search_domain_bounds', []), ...
    'empty_message', 'No valid pass-ratio gap point found within current search domain', ...
    'domain_summary', sprintf('h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
    'plot_domain_source', guard.plot_domain_source, ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
grid(ax2, 'on');

legend(ax1, 'Location', 'eastoutside', 'Box', 'off');
end

function values = local_getfield_or(T, field_name, fallback)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
elseif isstruct(T) && isfield(T, field_name)
    values = T.(field_name);
else
    values = fallback;
end
end

function local_plot_curve(ax, x_values, y_values, is_defined, line_spec, color_value, line_width, marker_size, label_text, max_gap_for_connect)
if nargin < 4 || isempty(is_defined)
    is_defined = isfinite(x_values) & isfinite(y_values);
end
segments = build_mb_polyline_segments_from_defined_points(x_values, y_values, is_defined, max_gap_for_connect);
if isempty(segments)
    return;
end
display_consumed = false;
for idx_seg = 1:numel(segments)
    seg = segments{idx_seg};
    if numel(seg.x) < 2
        plot(ax, seg.x, seg.y, line_spec(end), 'Color', color_value, 'LineWidth', line_width, ...
            'MarkerSize', marker_size + 1, 'MarkerFaceColor', color_value, ...
            'DisplayName', local_segment_label(label_text + " (isolated)", display_consumed));
    else
        plot(ax, seg.x, seg.y, line_spec, 'Color', color_value, 'LineWidth', line_width, ...
            'MarkerSize', marker_size, 'DisplayName', local_segment_label(label_text, display_consumed));
    end
    display_consumed = true;
end
end

function label = local_segment_label(label_text, consumed)
if consumed
    label = "";
else
    label = label_text;
end
end

function [legacy_plateau, closed_plateau, note] = local_plateau_status(gap_table, saturation_table)
legacy_plateau = false;
closed_plateau = false;
note = "";
if istable(saturation_table) && ~isempty(saturation_table) && ismember('semantic_mode', saturation_table.Properties.VariableNames)
    legacy_row = saturation_table(strcmpi(string(saturation_table.semantic_mode), "legacyDG"), :);
    closed_row = saturation_table(strcmpi(string(saturation_table.semantic_mode), "closedD"), :);
    if ~isempty(legacy_row)
        legacy_plateau = logical(legacy_row.right_unity_reached(1));
    end
    if ~isempty(closed_row)
        closed_plateau = logical(closed_row.right_unity_reached(1));
    end
    if ~legacy_plateau && ~closed_plateau
        note = "Unity plateau not reached for either legacyDG or closedD within the current search domain.";
    elseif ~legacy_plateau
        note = "Unity plateau not reached for legacyDG within the current search domain.";
    elseif ~closed_plateau
        note = "Unity plateau not reached for closedD within the current search domain.";
    end
    if legacy_plateau || closed_plateau || strlength(note) > 0
        return;
    end
end

i_values = unique(gap_table.i_deg, 'sorted');
legacy_final = nan(numel(i_values), 1);
closed_final = nan(numel(i_values), 1);
for idx = 1:numel(i_values)
    Ti = sortrows(gap_table(gap_table.i_deg == i_values(idx), :), 'Ns');
    if isempty(Ti)
        continue;
    end
    legacy_final(idx) = Ti.max_pass_ratio_legacyDG(end);
    closed_final(idx) = Ti.max_pass_ratio_closedD(end);
end

tol = 0.02;
legacy_plateau = all(legacy_final(~isnan(legacy_final)) >= 1 - tol);
closed_plateau = all(closed_final(~isnan(closed_final)) >= 1 - tol);
if legacy_plateau && closed_plateau
    return;
end
if ~legacy_plateau && ~closed_plateau
    note = "Unity plateau not reached for either legacyDG or closedD within the current tuned domain.";
elseif ~legacy_plateau
    note = "Unity plateau not reached for legacyDG within the current tuned domain.";
else
    note = "Unity plateau not reached for closedD within the current tuned domain.";
end
end

function local_add_boundary_note(ax, boundary_hit_table, options)
if ~local_show_annotations(options)
    return;
end
if isempty(boundary_hit_table) || ~istable(boundary_hit_table) || ~ismember('is_boundary_dominated', boundary_hit_table.Properties.VariableNames)
    return;
end
if any(boundary_hit_table.is_boundary_dominated)
    text(ax, 0.02, 0.72, 'status: boundary dominated', ...
        'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.55 0.15 0.15], ...
        'VerticalAlignment', 'top');
end
end

function tf = local_show_annotations(options)
style_mode = local_getfield_or(options, 'figure_style', struct());
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation')
    tf = logical(style_mode.show_diagnostic_annotation);
else
    tf = true;
end
end

function values = local_pick_logical(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = logical(T.(field_name));
else
    values = isfinite(local_getfield_or(T, field_name, []));
end
end

function step = local_resolve_base_grid_step(T)
step = NaN;
if istable(T) && ismember('base_grid_step', T.Properties.VariableNames)
    values = T.base_grid_step(isfinite(T.base_grid_step));
    if ~isempty(values)
        step = values(1);
        return;
    end
end
ns_values = unique(local_getfield_or(T, 'Ns', []), 'sorted');
ns_values = ns_values(isfinite(ns_values));
if numel(ns_values) >= 2
    step = min(diff(ns_values));
end
end
