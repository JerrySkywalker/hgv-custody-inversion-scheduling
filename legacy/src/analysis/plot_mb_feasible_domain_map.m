function fig = plot_mb_feasible_domain_map(hi_view_table, pt_view_table, minimum_design_table, style)
%PLOT_MB_FEASIBLE_DOMAIN_MAP Plot full-grid feasible-domain slices for Milestone B.

if nargin < 4 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
local_plot_slice(ax1, hi_view_table, minimum_design_table, 'i_deg', 'h_km', ...
    'i (deg)', 'h (km)', 'Milestone B h-i feasible slice');

ax2 = nexttile;
local_plot_slice(ax2, pt_view_table, minimum_design_table, 'P', 'T', ...
    'P', 'T', 'Milestone B P-T feasible slice');

colormap(fig, parula);
cb = colorbar(ax2);
cb.Label.String = 'N_s';

    function local_plot_slice(ax, view_table, min_table, xvar, yvar, xlabel_txt, ylabel_txt, title_txt)
        hold(ax, 'on');
        if isempty(view_table)
            plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
        else
            infeasible_mask = ~view_table.is_feasible;
            feasible_mask = view_table.is_feasible;

            if any(infeasible_mask)
                scatter(ax, view_table.(xvar)(infeasible_mask), view_table.(yvar)(infeasible_mask), ...
                    52, 'o', 'MarkerEdgeColor', [0.75, 0.75, 0.75], 'MarkerFaceColor', 'none', 'LineWidth', 0.9);
            end
            if any(feasible_mask)
                scatter(ax, view_table.(xvar)(feasible_mask), view_table.(yvar)(feasible_mask), ...
                    68, view_table.Ns(feasible_mask), 'filled', 'MarkerEdgeColor', [0.2, 0.2, 0.2], 'LineWidth', 0.6);
            end

            min_view = local_filter_minimum_for_view(min_table, view_table, xvar, yvar);
            if ~isempty(min_view)
                scatter(ax, min_view.(xvar), min_view.(yvar), 124, 'p', ...
                    'MarkerEdgeColor', style.threshold_color, 'MarkerFaceColor', [1.0, 0.95, 0.2], 'LineWidth', 1.2);
            end
        end
        hold(ax, 'off');
        xlabel(ax, xlabel_txt);
        ylabel(ax, ylabel_txt);
        title(ax, title_txt);
        grid(ax, 'on');
    end
end

function min_view = local_filter_minimum_for_view(min_table, view_table, xvar, yvar)
min_view = table();
if isempty(min_table) || isempty(view_table)
    return;
end

shared_vars = intersect({'h_km', 'i_deg', 'P', 'T', 'F'}, view_table.Properties.VariableNames, 'stable');
shared_vars = intersect(shared_vars, min_table.Properties.VariableNames, 'stable');
if isempty(shared_vars)
    return;
end

[tf, ~] = ismember(min_table(:, shared_vars), view_table(:, shared_vars), 'rows');
min_view = min_table(tf, :);
if ~isempty(min_view)
    min_view = unique(min_view(:, unique([{xvar, yvar}, shared_vars], 'stable')), 'rows');
end
end
