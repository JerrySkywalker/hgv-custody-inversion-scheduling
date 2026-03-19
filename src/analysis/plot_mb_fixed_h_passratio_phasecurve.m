function fig = plot_mb_fixed_h_passratio_phasecurve(phasecurve_table, h_km, style, options)
%PLOT_MB_FIXED_H_PASSRATIO_PHASECURVE Plot fixed-height pass-ratio profiles versus N_s.

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

if isfield(options, 'required_pass_ratio') && isfinite(options.required_pass_ratio)
    yline(ax, options.required_pass_ratio, ':', ...
        'Color', style.colors(2, :), ...
        'LineWidth', style.threshold_line_width, ...
        'DisplayName', sprintf('Required pass ratio = %.2f', options.required_pass_ratio));
end

xlabel(ax, 'N_s');
ylabel(ax, 'Max pass ratio under fixed i');
title(ax, sprintf('Pass-Ratio Profile versus N_s at h = %.0f km', h_km));
if isfield(options, 'plot_xlim_ns') && numel(options.plot_xlim_ns) == 2 && all(isfinite(options.plot_xlim_ns))
    xlim(ax, reshape(options.plot_xlim_ns, 1, []));
end
if isfield(options, 'plot_ylim_passratio') && numel(options.plot_ylim_passratio) == 2 && all(isfinite(options.plot_ylim_passratio))
    ylim(ax, reshape(options.plot_ylim_passratio, 1, []));
else
    ylim(ax, [0, 1.05]);
end
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end
