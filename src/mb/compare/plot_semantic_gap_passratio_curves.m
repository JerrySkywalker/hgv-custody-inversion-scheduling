function fig = plot_semantic_gap_passratio_curves(gap_table, h_km, sensor_label)
%PLOT_SEMANTIC_GAP_PASSRATIO_CURVES Plot overlay and gap curves for pass ratio.

if nargin < 3
    sensor_label = "";
end

i_values = unique(gap_table.i_deg, 'sorted');
cmap = turbo(max(2, numel(i_values)));

fig = figure('Visible', 'off', 'Color', 'w');
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

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
title(ax1, sprintf('Semantic Pass-Ratio Overlay at h = %.0f km [%s]', h_km, char(string(sensor_label))));
grid(ax1, 'on');
ylim(ax1, [0, 1.05]);

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
title(ax2, '\Delta pass ratio (closedD - legacyDG)');
text(ax2, 0.02, 0.92, 'Positive: closedD higher | Negative: legacyDG higher', ...
    'Units', 'normalized', 'FontSize', 10, 'Color', [0.25 0.25 0.25], ...
    'VerticalAlignment', 'top');
grid(ax2, 'on');

legend(ax1, 'Location', 'eastoutside', 'Box', 'off');
end
