function fig = plot_mb_minimum_design_map(feasible_theta_table, minimum_design_table, near_optimal_table, style, baseline_theta)
%PLOT_MB_MINIMUM_DESIGN_MAP Plot feasible, near-optimal, and minimum designs for MB.

if nargin < 4 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 5
    baseline_theta = struct();
end

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
sgtitle(fig, 'Milestone B Minimum Design and Near-Optimal Region');

ax1 = nexttile;
local_plot_projection(ax1, feasible_theta_table, near_optimal_table, minimum_design_table, ...
    'i_deg', 'h_km', 'i (deg)', 'h (km)', 'h-i Projection', style, baseline_theta);

ax2 = nexttile;
local_plot_projection(ax2, feasible_theta_table, near_optimal_table, minimum_design_table, ...
    'P', 'T', 'P', 'T', 'P-T Projection', style, baseline_theta);

if ~isempty(near_optimal_table)
    cb = colorbar(ax2);
    cb.Label.String = 'N_s';
end
end

function local_plot_projection(ax, feasible_theta_table, near_optimal_table, minimum_design_table, xvar, yvar, xlabel_txt, ylabel_txt, title_txt, style, baseline_theta)
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
if local_has_baseline(baseline_theta, xvar, yvar)
    scatter(ax, baseline_theta.(xvar), baseline_theta.(yvar), 110, 'd', ...
        'MarkerEdgeColor', [0.1, 0.1, 0.1], 'MarkerFaceColor', [0.95, 0.45, 0.2], 'LineWidth', 1.1);
end
hold(ax, 'off');
xlabel(ax, xlabel_txt);
ylabel(ax, ylabel_txt);
title(ax, title_txt);
grid(ax, 'on');
end

function tf = local_has_baseline(baseline_theta, xvar, yvar)
tf = isstruct(baseline_theta) && isfield(baseline_theta, xvar) && isfield(baseline_theta, yvar);
end
