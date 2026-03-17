function fig = plot_mb_minimum_design_map(feasible_theta_table, minimum_design_table, near_optimal_table, style)
%PLOT_MB_MINIMUM_DESIGN_MAP Plot feasible, near-optimal, and minimum designs for MB.

if nargin < 4 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
local_plot_projection(ax1, feasible_theta_table, near_optimal_table, minimum_design_table, ...
    'i_deg', 'h_km', 'i (deg)', 'h (km)', 'Feasible / Near-Optimal / Minimum in h-i', style);

ax2 = nexttile;
local_plot_projection(ax2, feasible_theta_table, near_optimal_table, minimum_design_table, ...
    'P', 'T', 'P', 'T', 'Feasible / Near-Optimal / Minimum in P-T', style);

if ~isempty(near_optimal_table)
    cb = colorbar(ax2);
    cb.Label.String = 'N_s';
end
end

function local_plot_projection(ax, feasible_theta_table, near_optimal_table, minimum_design_table, xvar, yvar, xlabel_txt, ylabel_txt, title_txt, style)
hold(ax, 'on');
if ~isempty(feasible_theta_table)
    scatter(ax, feasible_theta_table.(xvar), feasible_theta_table.(yvar), 26, [0.84, 0.86, 0.9], ...
        'filled', 'MarkerEdgeColor', 'none');
end
if ~isempty(near_optimal_table)
    scatter(ax, near_optimal_table.(xvar), near_optimal_table.(yvar), 78, near_optimal_table.Ns, ...
        'filled', 'MarkerEdgeColor', [0.15, 0.2, 0.25], 'LineWidth', 0.6);
end
if ~isempty(minimum_design_table)
    scatter(ax, minimum_design_table.(xvar), minimum_design_table.(yvar), 144, 'p', ...
        'MarkerEdgeColor', style.threshold_color, 'MarkerFaceColor', [1.0, 0.9, 0.2], 'LineWidth', 1.3);
end
hold(ax, 'off');
xlabel(ax, xlabel_txt);
ylabel(ax, ylabel_txt);
title(ax, title_txt);
grid(ax, 'on');
end
