function fig = plot_mb_phasecurve_by_family(phasecurve_table, metric_name, style)
%PLOT_MB_PHASECURVE_BY_FAMILY Plot family-level phase-transition curves over constellation size.

if nargin < 2 || isempty(metric_name)
    metric_name = 'best_joint_margin_feasible';
end
if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(phasecurve_table) || ~ismember(metric_name, phasecurve_table.Properties.VariableNames)
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
else
    families = unique(string(phasecurve_table.family_name), 'stable');
    cmap = lines(max(3, numel(families)));
    for idx = 1:numel(families)
        sub = phasecurve_table(string(phasecurve_table.family_name) == families(idx), :);
        plot(ax, sub.Ns, sub.(metric_name), '-o', ...
            'Color', cmap(idx, :), ...
            'LineWidth', style.line_width, ...
            'MarkerSize', style.marker_size, ...
            'DisplayName', char(families(idx)));
    end
end

xlabel(ax, 'N_s');
ylabel(ax, local_metric_label(metric_name));
title(ax, local_metric_title(metric_name));
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end

function txt = local_metric_label(metric_name)
switch char(string(metric_name))
    case 'best_joint_margin_feasible'
        txt = 'Best feasible joint margin';
    case 'best_joint_margin_all'
        txt = 'Best joint margin';
    case 'feasible_ratio'
        txt = 'Feasible ratio';
    otherwise
        txt = char(string(metric_name));
end
end

function txt = local_metric_title(metric_name)
switch char(string(metric_name))
    case 'best_joint_margin_feasible'
        txt = 'Family Best Feasible Joint Margin vs N_s';
    case 'best_joint_margin_all'
        txt = 'Family Best Joint Margin vs N_s';
    case 'feasible_ratio'
        txt = 'Family Feasible Ratio vs N_s';
    otherwise
        txt = sprintf('Family Phase Curve: %s', char(string(metric_name)));
end
end
