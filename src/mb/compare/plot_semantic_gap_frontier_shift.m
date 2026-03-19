function fig = plot_semantic_gap_frontier_shift(gap_table, h_km, sensor_label)
%PLOT_SEMANTIC_GAP_FRONTIER_SHIFT Plot legacyDG/closedD frontier overlay and shift summary.

if nargin < 3
    sensor_label = "";
end

fig = figure('Visible', 'off', 'Color', 'w');
tiled = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tiled, 1);
hold(ax1, 'on');
plot(ax1, gap_table.i_deg, gap_table.minimum_feasible_Ns_legacyDG, '--s', ...
    'Color', [0.15, 0.35, 0.75], 'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'legacyDG');
plot(ax1, gap_table.i_deg, gap_table.minimum_feasible_Ns_closedD, '-o', ...
    'Color', [0.8, 0.25, 0.15], 'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'closedD');
xlabel(ax1, 'i (deg)');
ylabel(ax1, 'minimum feasible N_s');
title(ax1, sprintf('Frontier Overlay at h = %.0f km [%s]', h_km, char(string(sensor_label))));
grid(ax1, 'on');
legend(ax1, 'Location', 'best', 'Box', 'off');

ax2 = nexttile(tiled, 2);
hold(ax2, 'on');
finite_mask = isfinite(gap_table.delta_Ns);
plot(ax2, gap_table.i_deg(finite_mask), gap_table.delta_Ns(finite_mask), '-o', ...
    'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.6, 'MarkerSize', 6);
inf_mask = isinf(gap_table.delta_Ns) & gap_table.delta_Ns > 0;
if any(inf_mask)
    plot(ax2, gap_table.i_deg(inf_mask), repmat(max([1; gap_table.minimum_feasible_Ns_legacyDG(isfinite(gap_table.minimum_feasible_Ns_legacyDG))]) + 10, sum(inf_mask), 1), 'x', ...
        'Color', [0.8, 0.15, 0.15], 'LineWidth', 2.0, 'MarkerSize', 8, 'DisplayName', 'closedD infeasible');
end
yline(ax2, 0, ':', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.1);
xlabel(ax2, 'i (deg)');
ylabel(ax2, '\Delta N_s');
title(ax2, 'Frontier Shift (closedD - legacyDG)');
grid(ax2, 'on');
end
