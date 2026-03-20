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
    'empty_message', 'No valid pass-ratio comparison point found within current search domain'));

fig = figure('Visible', 'off', 'Color', 'w');
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tiled, sprintf('Comparison Pass-Ratio Diagnostics at h = %.0f km [%s]', h_km, char(string(sensor_label))));

ax1 = nexttile(tiled, 1);
hold(ax1, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    local_plot_curve(ax1, Ti.Ns, Ti.max_pass_ratio_legacyDG, '--s', cmap(idx, :), 1.5, 5, sprintf('legacyDG i=%g', i_values(idx)));
    local_plot_curve(ax1, Ti.Ns, Ti.max_pass_ratio_closedD, '-o', cmap(idx, :), 1.8, 5, sprintf('closedD i=%g', i_values(idx)));
end
ylabel(ax1, 'max pass ratio');
title(ax1, 'Upper panel: pass ratio overlay');
grid(ax1, 'on');
apply_mb_plot_domain_guardrail(ax1, local_getfield_or(gap_table, 'Ns', []), local_getfield_or(gap_table, 'max_pass_ratio_closedD', []), struct( ...
    'ylim', [0, 1.05], ...
    'empty_message', 'No valid pass-ratio comparison point found within current search domain', ...
    'domain_summary', sprintf('Search domain: h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
    'plot_domain_source', guard.plot_domain_source));
text(ax1, 0.02, 0.96, 'Upper: legacyDG vs closedD pass ratio under the shared N_s domain', ...
    'Units', 'normalized', 'FontSize', 10, 'Color', [0.20 0.20 0.20], 'VerticalAlignment', 'top');

[legacy_plateau, closed_plateau, plateau_note] = local_plateau_status(gap_table, local_getfield_or(options, 'passratio_saturation_table', table()));
if strlength(plateau_note) > 0
    text(ax1, 0.02, 0.84, char(plateau_note), ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.55 0.15 0.15], 'VerticalAlignment', 'top');
end

ax2 = nexttile(tiled, 2);
hold(ax2, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    local_plot_curve(ax2, Ti.Ns, Ti.passratio_gap, '-o', cmap(idx, :), 1.6, 5, sprintf('gap i=%g', i_values(idx)));
end
yline(ax2, 0, ':', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.1);
xlabel(ax2, 'N_s');
ylabel(ax2, '\Delta pass ratio');
title(ax2, 'Lower panel: \Delta pass ratio (closedD - legacyDG)');
text(ax2, 0.02, 0.92, 'Negative gap means closedD is more conservative than legacyDG', ...
    'Units', 'normalized', 'FontSize', 10, 'Color', [0.25 0.25 0.25], ...
    'VerticalAlignment', 'top');
if ~(legacy_plateau && closed_plateau)
    text(ax2, 0.02, 0.82, 'Search domain not yet saturated: unity plateau not reached within current tuned domain.', ...
        'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.55 0.15 0.15], ...
        'VerticalAlignment', 'top');
end
local_add_boundary_note(ax2, local_getfield_or(options, 'boundary_hit_table', table()));
apply_mb_plot_domain_guardrail(ax2, local_getfield_or(gap_table, 'Ns', []), local_getfield_or(gap_table, 'passratio_gap', []), struct( ...
    'empty_message', 'No valid pass-ratio gap point found within current search domain', ...
    'domain_summary', sprintf('Search domain: h = %.0f km [%s]', h_km, char(string(sensor_label))), ...
    'plot_domain_source', guard.plot_domain_source));
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

function local_plot_curve(ax, x_values, y_values, line_spec, color_value, line_width, marker_size, label_text)
valid_mask = isfinite(x_values) & isfinite(y_values);
x_values = x_values(valid_mask);
y_values = y_values(valid_mask);
if isempty(x_values)
    return;
elseif numel(unique(x_values)) < 2
    plot(ax, x_values, y_values, line_spec(end), 'Color', color_value, 'LineWidth', line_width, ...
        'MarkerSize', marker_size + 1, 'MarkerFaceColor', color_value, 'DisplayName', sprintf('%s (single point)', label_text));
else
    plot(ax, x_values, y_values, line_spec, 'Color', color_value, 'LineWidth', line_width, ...
        'MarkerSize', marker_size, 'DisplayName', label_text);
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

function local_add_boundary_note(ax, boundary_hit_table)
if isempty(boundary_hit_table) || ~istable(boundary_hit_table) || ~ismember('is_boundary_dominated', boundary_hit_table.Properties.VariableNames)
    return;
end
if any(boundary_hit_table.is_boundary_dominated)
    text(ax, 0.02, 0.72, 'Boundary-dominated heatmap context: minimum-N_s cells sit on the current search upper bound.', ...
        'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.55 0.15 0.15], ...
        'VerticalAlignment', 'top');
end
end
