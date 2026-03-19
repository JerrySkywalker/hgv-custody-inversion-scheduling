function fig = plot_semantic_gap_passratio_curves(gap_table, h_km, sensor_label)
%PLOT_SEMANTIC_GAP_PASSRATIO_CURVES Plot overlay and gap curves for pass ratio.

if nargin < 3
    sensor_label = "";
end

i_values = unique(gap_table.i_deg, 'sorted');
cmap = turbo(max(2, numel(i_values)));

fig = figure('Visible', 'off', 'Color', 'w');
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tiled, sprintf('Comparison Pass-Ratio Diagnostics at h = %.0f km [%s]', h_km, char(string(sensor_label))));

ax1 = nexttile(tiled, 1);
hold(ax1, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    plot(ax1, Ti.Ns, Ti.max_pass_ratio_legacyDG, '--s', ...
        'Color', cmap(idx, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('legacyDG i=%g', i_values(idx)));
    plot(ax1, Ti.Ns, Ti.max_pass_ratio_closedD, '-o', ...
        'Color', cmap(idx, :), 'LineWidth', 1.8, 'MarkerSize', 5, ...
        'DisplayName', sprintf('closedD i=%g', i_values(idx)));
end
ylabel(ax1, 'max pass ratio');
title(ax1, 'Upper panel: pass ratio overlay');
grid(ax1, 'on');
ylim(ax1, [0, 1.05]);
text(ax1, 0.02, 0.96, 'Upper: legacyDG vs closedD pass ratio under the shared N_s domain', ...
    'Units', 'normalized', 'FontSize', 10, 'Color', [0.20 0.20 0.20], 'VerticalAlignment', 'top');

[legacy_plateau, closed_plateau, plateau_note] = local_plateau_status(gap_table);
if strlength(plateau_note) > 0
    text(ax1, 0.02, 0.84, char(plateau_note), ...
        'Units', 'normalized', 'FontSize', 10, 'Color', [0.55 0.15 0.15], 'VerticalAlignment', 'top');
end

ax2 = nexttile(tiled, 2);
hold(ax2, 'on');
for idx = 1:numel(i_values)
    Ti = gap_table(gap_table.i_deg == i_values(idx), :);
    Ti = sortrows(Ti, 'Ns');
    plot(ax2, Ti.Ns, Ti.passratio_gap, '-o', ...
        'Color', cmap(idx, :), 'LineWidth', 1.6, 'MarkerSize', 5, ...
        'DisplayName', sprintf('gap i=%g', i_values(idx)));
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
grid(ax2, 'on');

legend(ax1, 'Location', 'eastoutside', 'Box', 'off');
end

function [legacy_plateau, closed_plateau, note] = local_plateau_status(gap_table)
legacy_plateau = false;
closed_plateau = false;
note = "";
if isempty(gap_table) || ~all(ismember({'i_deg', 'Ns', 'max_pass_ratio_legacyDG', 'max_pass_ratio_closedD'}, gap_table.Properties.VariableNames))
    return;
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
