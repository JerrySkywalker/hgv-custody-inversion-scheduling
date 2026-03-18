function [fig, phasecurve_table] = plot_mb_passratio_phasecurve_by_i(full_theta_table, family_name, i_list, style, options)
%PLOT_MB_PASSRATIO_PHASECURVE_BY_I Plot pass-ratio envelopes versus constellation size for fixed inclinations.

if nargin < 2 || isempty(family_name)
    family_name = "joint";
end
if nargin < 3 || isempty(i_list)
    if isempty(full_theta_table)
        i_list = [];
    else
        i_list = unique(full_theta_table.i_deg, 'sorted');
    end
end
if nargin < 4 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 5 || isempty(options)
    options = struct();
end

phasecurve_table = local_build_phasecurve_table(full_theta_table, i_list);
fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

if isempty(phasecurve_table)
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :));
else
    unique_i = unique(phasecurve_table.i_deg, 'sorted');
    cmap = turbo(max(2, numel(unique_i)));
    for idx = 1:numel(unique_i)
        sub = phasecurve_table(phasecurve_table.i_deg == unique_i(idx), :);
        plot(ax, sub.Ns, sub.max_pass_ratio, '-o', ...
            'Color', cmap(idx, :), ...
            'LineWidth', style.line_width, ...
            'MarkerSize', style.marker_size, ...
            'DisplayName', sprintf('i = %.0f deg', unique_i(idx)));
    end
end

if isfield(options, 'minimum_shell_Ns') && isfinite(options.minimum_shell_Ns)
    xline(ax, options.minimum_shell_Ns, '--', ...
        'Color', style.threshold_color, ...
        'LineWidth', style.threshold_line_width, ...
        'DisplayName', sprintf('Joint minimum shell N_s = %d', round(options.minimum_shell_Ns)));
end
if isfield(options, 'required_pass_ratio') && isfinite(options.required_pass_ratio)
    yline(ax, options.required_pass_ratio, ':', ...
        'Color', style.colors(2, :), ...
        'LineWidth', style.threshold_line_width, ...
        'DisplayName', sprintf('Required pass ratio = %.2f', options.required_pass_ratio));
end

xlabel(ax, 'N_s');
ylabel(ax, 'Max pass ratio');
title(ax, sprintf('Pass-Ratio Phase Curve (%s)', upper(char(string(family_name)))));
ylim(ax, [0, 1.05]);
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end

function phasecurve_table = local_build_phasecurve_table(full_theta_table, i_list)
phasecurve_table = table();
if isempty(full_theta_table) || ~ismember('pass_ratio', full_theta_table.Properties.VariableNames)
    return;
end

rows = cell(height(full_theta_table), 1);
row_count = 0;
for idx = 1:numel(i_list)
    sub_i = full_theta_table(full_theta_table.i_deg == i_list(idx), :);
    if isempty(sub_i)
        continue;
    end
    Ns_values = unique(sub_i.Ns, 'sorted');
    for j = 1:numel(Ns_values)
        sub_ns = sub_i(sub_i.Ns == Ns_values(j), :);
        row_count = row_count + 1;
        rows{row_count, 1} = table(i_list(idx), Ns_values(j), max(sub_ns.pass_ratio), ...
            sum(local_pick_feasible(sub_ns)), height(sub_ns), ...
            'VariableNames', {'i_deg', 'Ns', 'max_pass_ratio', 'num_feasible', 'num_total'});
    end
end

rows = rows(1:row_count);
if ~isempty(rows)
    phasecurve_table = vertcat(rows{:});
    phasecurve_table = sortrows(phasecurve_table, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
end
end

function feasible_mask = local_pick_feasible(T)
if ismember('feasible_flag', T.Properties.VariableNames)
    feasible_mask = logical(T.feasible_flag);
elseif ismember('joint_feasible', T.Properties.VariableNames)
    feasible_mask = logical(T.joint_feasible);
else
    feasible_mask = false(height(T), 1);
end
end
