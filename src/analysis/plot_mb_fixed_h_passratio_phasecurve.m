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

guard = compute_mb_plot_window_from_data(local_getfield_or(phasecurve_table, 'Ns', []), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'empty_message', 'No valid pass-ratio point found within current search domain'));

if isempty(phasecurve_table)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No valid pass-ratio point found within current search domain', ...
        'domain_summary', sprintf('Search domain: h = %.0f km', h_km), ...
        'plot_domain_source', guard.plot_domain_source));
else
    unique_i = unique(phasecurve_table.i_deg, 'sorted');
    cmap = turbo(max(2, numel(unique_i)));
    for idx = 1:numel(unique_i)
        sub = phasecurve_table(phasecurve_table.i_deg == unique_i(idx), :);
        sub = sortrows(sub, 'Ns');
        valid_mask = isfinite(sub.Ns) & isfinite(sub.max_pass_ratio);
        sub = sub(valid_mask, :);
        if isempty(sub)
            continue;
        elseif numel(unique(sub.Ns)) < 2
            plot(ax, sub.Ns, sub.max_pass_ratio, 'o', ...
                'Color', cmap(idx, :), ...
                'LineWidth', style.line_width, ...
                'MarkerSize', style.marker_size + 1, ...
                'MarkerFaceColor', cmap(idx, :), ...
                'DisplayName', sprintf('i = %.0f deg (single point)', unique_i(idx)));
        else
            plot(ax, sub.Ns, sub.max_pass_ratio, '-o', ...
                'Color', cmap(idx, :), ...
                'LineWidth', style.line_width, ...
                'MarkerSize', style.marker_size, ...
                'DisplayName', sprintf('i = %.0f deg', unique_i(idx)));
        end
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
apply_mb_plot_domain_guardrail(ax, local_getfield_or(phasecurve_table, 'Ns', []), local_getfield_or(phasecurve_table, 'max_pass_ratio', []), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'ylim', local_resolve_ylim(options), ...
    'empty_message', 'No valid pass-ratio point found within current search domain', ...
    'domain_summary', sprintf('Search domain: h = %.0f km', h_km), ...
    'plot_domain_source', guard.plot_domain_source));
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end

function values = local_getfield_or(T, field_name, fallback)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
elseif isstruct(T) && isfield(T, field_name)
    values = T.(field_name);
else
    values = fallback;
end
end

function ylim_values = local_resolve_ylim(options)
if isfield(options, 'plot_ylim_passratio') && numel(options.plot_ylim_passratio) == 2 && all(isfinite(options.plot_ylim_passratio))
    ylim_values = reshape(options.plot_ylim_passratio, 1, []);
else
    ylim_values = [0, 1.05];
end
end
