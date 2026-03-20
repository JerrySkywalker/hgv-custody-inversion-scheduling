function fig = plot_semantic_gap_frontier_shift(gap_table, h_km, sensor_label, options)
%PLOT_SEMANTIC_GAP_FRONTIER_SHIFT Plot legacyDG/closedD frontier overlay and shift summary.

if nargin < 3
    sensor_label = "";
end
if nargin < 4 || isempty(options)
    options = struct();
end

fig = figure('Visible', 'off', 'Color', 'w');
setappdata(fig, 'mb_figure_style', local_getfield_or(options, 'figure_style', struct()));
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
diagnostic_note = local_frontier_diagnostic_note(gap_table);
truncation_table = local_getfield_or(options, 'frontier_truncation_table', table());

ax1 = nexttile(tiled, 1);
hold(ax1, 'on');
if isempty(gap_table) || ~ismember('i_deg', gap_table.Properties.VariableNames)
    apply_mb_plot_domain_guardrail(ax1, [], [], struct( ...
        'empty_message', 'No valid frontier points in current search domain', ...
        'domain_summary', sprintf('Frontier overlay unavailable at h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
        'plot_domain_source', "no_frontier_table"));
else
    legacy_valid = isfinite(gap_table.minimum_feasible_Ns_legacyDG);
    closed_valid = isfinite(gap_table.minimum_feasible_Ns_closedD);
    if any(legacy_valid)
        local_plot_frontier(ax1, gap_table.i_deg(legacy_valid), gap_table.minimum_feasible_Ns_legacyDG(legacy_valid), '--s', [0.15, 0.35, 0.75], 'legacyDG');
    end
    if any(closed_valid)
        local_plot_frontier(ax1, gap_table.i_deg(closed_valid), gap_table.minimum_feasible_Ns_closedD(closed_valid), '-o', [0.8, 0.25, 0.15], 'closedD');
    end
    if ~any(legacy_valid) && ~any(closed_valid)
        apply_mb_plot_domain_guardrail(ax1, [], [], struct( ...
            'empty_message', 'No valid frontier points in current search domain', ...
            'domain_summary', sprintf('Neither legacyDG nor closedD frontier is defined at h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
            'plot_domain_source', "no_valid_frontier", ...
            'figure_style', local_getfield_or(options, 'figure_style', struct())));
    else
        apply_mb_plot_domain_guardrail(ax1, gap_table.i_deg(legacy_valid | closed_valid), [gap_table.minimum_feasible_Ns_legacyDG(legacy_valid); gap_table.minimum_feasible_Ns_closedD(closed_valid)], struct( ...
            'min_span', 10, ...
            'auto_ylim', true, ...
            'empty_message', 'No valid frontier points in current search domain', ...
            'domain_summary', local_frontier_note(legacy_valid, closed_valid), ...
            'plot_domain_source', "frontier_overlay", ...
            'figure_style', local_getfield_or(options, 'figure_style', struct())));
    end
end
xlabel(ax1, 'i (deg)');
ylabel(ax1, 'minimum feasible N_s');
title(ax1, sprintf('Frontier Overlay at h = %.0f km [%s]', h_km, char(string(sensor_label))));
if local_show_annotations(options) && strlength(diagnostic_note) > 0
    text(ax1, 0.02, 0.94, char(diagnostic_note), ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.25 0.25 0.25], ...
        'VerticalAlignment', 'top');
end
local_add_truncation_note(ax1, truncation_table);
grid(ax1, 'on');
legend(ax1, 'Location', 'best', 'Box', 'off');

ax2 = nexttile(tiled, 2);
hold(ax2, 'on');
if isempty(gap_table) || ~ismember('delta_Ns', gap_table.Properties.VariableNames)
    apply_mb_plot_domain_guardrail(ax2, [], [], struct( ...
        'empty_message', 'No valid frontier shift point in current search domain', ...
        'domain_summary', sprintf('Frontier shift unavailable at h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
        'plot_domain_source', "no_gap_table"));
else
    finite_mask = isfinite(gap_table.delta_Ns);
    if any(finite_mask)
        local_plot_frontier(ax2, gap_table.i_deg(finite_mask), gap_table.delta_Ns(finite_mask), '-o', [0.25, 0.25, 0.25], '\Delta N_s');
        yline(ax2, 0, ':', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.1);
        apply_mb_plot_domain_guardrail(ax2, gap_table.i_deg(finite_mask), gap_table.delta_Ns(finite_mask), struct( ...
            'min_span', 10, ...
            'auto_ylim', true, ...
            'empty_message', 'No valid frontier shift point in current search domain', ...
            'domain_summary', 'Only defined \Delta N_s values are shown; missing frontier pairs are left undefined.', ...
            'plot_domain_source', "frontier_shift", ...
            'figure_style', local_getfield_or(options, 'figure_style', struct())));
    else
        apply_mb_plot_domain_guardrail(ax2, [], [], struct( ...
            'empty_message', 'No valid frontier shift point in current search domain', ...
            'domain_summary', 'Delta N_s is undefined because at least one semantic frontier is missing for every inclination.', ...
            'plot_domain_source', "undefined_delta", ...
            'figure_style', local_getfield_or(options, 'figure_style', struct())));
    end
end
xlabel(ax2, 'i (deg)');
ylabel(ax2, '\Delta N_s');
title(ax2, 'Frontier Shift (closedD - legacyDG)');
local_add_truncation_note(ax2, truncation_table);
grid(ax2, 'on');
end

function local_plot_frontier(ax, x_values, y_values, line_spec, color_value, label_text)
valid_mask = isfinite(x_values) & isfinite(y_values);
x_values = x_values(valid_mask);
y_values = y_values(valid_mask);
if isempty(x_values)
    return;
elseif numel(unique(x_values)) < 2
    plot(ax, x_values, y_values, line_spec(end), 'Color', color_value, 'LineWidth', 1.8, ...
        'MarkerSize', 7, 'MarkerFaceColor', color_value, 'DisplayName', sprintf('%s (single point)', label_text));
else
    plot(ax, x_values, y_values, line_spec, 'Color', color_value, 'LineWidth', 1.8, ...
        'MarkerSize', 6, 'DisplayName', label_text);
end
end

function note = local_frontier_note(legacy_valid, closed_valid)
if any(legacy_valid) && any(closed_valid)
    note = 'Both legacyDG and closedD frontiers are available within the current search domain.';
elseif any(legacy_valid)
    note = 'Only legacyDG frontier is defined within the current search domain; closedD frontier is missing.';
elseif any(closed_valid)
    note = 'Only closedD frontier is defined within the current search domain; legacyDG frontier is missing.';
else
    note = 'No valid frontier points are available within the current search domain.';
end
end

function note = local_frontier_diagnostic_note(gap_table)
note = "";
if isempty(gap_table) || ~all(ismember({'legacy_frontier_status', 'closedD_frontier_status'}, gap_table.Properties.VariableNames))
    return;
end

legacy_defined = sum(strcmp(gap_table.legacy_frontier_status, "defined"));
closed_defined = sum(strcmp(gap_table.closedD_frontier_status, "defined"));
delta_defined = 0;
if ismember('delta_Ns', gap_table.Properties.VariableNames)
    delta_defined = sum(isfinite(gap_table.delta_Ns));
end
note = sprintf('defined points: legacyDG=%d, closedD=%d, delta=%d', legacy_defined, closed_defined, delta_defined);
end

function local_add_truncation_note(ax, truncation_table)
style_mode = getappdata(ancestor(ax, 'figure'), 'mb_figure_style');
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation') && ~logical(style_mode.show_diagnostic_annotation)
    return;
end
if isempty(truncation_table) || ~istable(truncation_table) || ~ismember('diagnostic_note', truncation_table.Properties.VariableNames)
    return;
end
notes = unique(string(truncation_table.diagnostic_note));
notes = notes(strlength(notes) > 0);
if isempty(notes)
    return;
end
text(ax, 0.02, 0.86, char(strjoin(notes, newline)), ...
    'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.55 0.15 0.15], ...
    'VerticalAlignment', 'top');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
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
