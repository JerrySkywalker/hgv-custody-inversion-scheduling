function fig = plot_mb_minimum_design_map(feasible_theta_table, minimum_design_table, near_optimal_table, style)
%PLOT_MB_MINIMUM_DESIGN_MAP Plot feasible, near-optimal, and minimum designs for MB.

if nargin < 4 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if ~isempty(feasible_theta_table)
    scatter(ax, feasible_theta_table.i_deg, feasible_theta_table.h_km, 32, [0.82, 0.86, 0.9], ...
        'filled', 'MarkerEdgeColor', 'none');
end
if ~isempty(near_optimal_table)
    scatter(ax, near_optimal_table.i_deg, near_optimal_table.h_km, 72, near_optimal_table.Ns, ...
        'filled', 'MarkerEdgeColor', [0.15, 0.2, 0.25], 'LineWidth', 0.6);
end
if ~isempty(minimum_design_table)
    scatter(ax, minimum_design_table.i_deg, minimum_design_table.h_km, 144, 'p', ...
        'MarkerEdgeColor', style.threshold_color, 'MarkerFaceColor', [1.0, 0.9, 0.2], 'LineWidth', 1.3);
end

hold(ax, 'off');
xlabel(ax, 'i (deg)');
ylabel(ax, 'h (km)');
title(ax, 'Milestone B Minimum Design Candidates');
grid(ax, 'on');
if ~isempty(near_optimal_table)
    cb = colorbar(ax);
    cb.Label.String = 'N_s';
end
end
