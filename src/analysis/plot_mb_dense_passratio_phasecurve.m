function fig = plot_mb_dense_passratio_phasecurve(phasecurve_table, family_name, style, options)
%PLOT_MB_DENSE_PASSRATIO_PHASECURVE Plot dense local pass-ratio envelopes versus constellation size.

if nargin < 2 || isempty(family_name)
    family_name = "joint";
end
if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 4 || isempty(options)
    options = struct();
end

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
title(ax, sprintf('Dense Local Pass-Ratio Phase Curve (%s)', upper(char(string(family_name)))));
ylim(ax, [0, 1.05]);
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end
