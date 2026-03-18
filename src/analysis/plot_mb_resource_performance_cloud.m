function fig = plot_mb_resource_performance_cloud(feasible_theta_table, minimum_design_table, shell_candidate_table, metric_name, style)
%PLOT_MB_RESOURCE_PERFORMANCE_CLOUD Plot feasible, minimum, and shell-near-optimal designs in resource-performance space.

if nargin < 4 || isempty(metric_name)
    metric_name = 'joint_margin';
end
if nargin < 5 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(feasible_theta_table) || ~ismember(metric_name, feasible_theta_table.Properties.VariableNames)
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
else
    scatter(ax, feasible_theta_table.Ns, feasible_theta_table.(metric_name), ...
        36, feasible_theta_table.i_deg, 'o', 'filled', ...
        'MarkerFaceAlpha', 0.45, ...
        'MarkerEdgeColor', [0.2, 0.2, 0.2], ...
        'LineWidth', 0.4, ...
        'DisplayName', 'Feasible designs');
    cb = colorbar(ax);
    cb.Label.String = 'i (deg)';
end

shell_near = local_pick_shell_near_optimal(shell_candidate_table);
if ~isempty(shell_near) && ismember(metric_name, shell_near.Properties.VariableNames)
    scatter(ax, shell_near.Ns, shell_near.(metric_name), ...
        72, shell_near.i_deg, 'd', 'filled', ...
        'MarkerEdgeColor', style.colors(2, :), ...
        'LineWidth', 0.9, ...
        'DisplayName', 'Shell-near-optimal');
end

if ~isempty(minimum_design_table) && ismember(metric_name, minimum_design_table.Properties.VariableNames)
    scatter(ax, minimum_design_table.Ns, minimum_design_table.(metric_name), ...
        126, minimum_design_table.i_deg, 'p', ...
        'MarkerFaceColor', [1.0, 0.92, 0.15], ...
        'MarkerEdgeColor', style.threshold_color, ...
        'LineWidth', 1.1, ...
        'DisplayName', 'Minimum shell');
end

xlabel(ax, 'N_s');
ylabel(ax, local_metric_label(metric_name));
title(ax, local_metric_title(metric_name));
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end

function T = local_pick_shell_near_optimal(shell_candidate_table)
T = table();
if isempty(shell_candidate_table)
    return;
end

if ~ismember('joint_feasible', shell_candidate_table.Properties.VariableNames)
    return;
end
mask = logical(shell_candidate_table.joint_feasible);
if ismember('near_optimal_by_margin', shell_candidate_table.Properties.VariableNames)
    mask = mask & logical(shell_candidate_table.near_optimal_by_margin);
elseif ismember('near_optimal_by_size', shell_candidate_table.Properties.VariableNames)
    mask = mask & logical(shell_candidate_table.near_optimal_by_size);
end
T = shell_candidate_table(mask, :);
if ~isempty(T)
    T = unique_design_rows(T);
end
end

function txt = local_metric_label(metric_name)
switch char(string(metric_name))
    case 'joint_margin'
        txt = 'Joint margin';
    case 'DT_worst'
        txt = 'DT worst margin';
    otherwise
        txt = char(string(metric_name));
end
end

function txt = local_metric_title(metric_name)
switch char(string(metric_name))
    case 'joint_margin'
        txt = 'Resource-Performance Cloud: Joint Margin';
    case 'DT_worst'
        txt = 'Resource-Performance Cloud: Temporal Margin';
    otherwise
        txt = sprintf('Resource-Performance Cloud: %s', char(string(metric_name)));
end
end
