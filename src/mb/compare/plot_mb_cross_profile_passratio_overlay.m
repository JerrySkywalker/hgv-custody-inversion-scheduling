function fig = plot_mb_cross_profile_passratio_overlay(overlay_table, summary_table, h_km, semantic_mode, family_name)
%PLOT_MB_CROSS_PROFILE_PASSRATIO_OVERLAY Plot sensor-group overlays of pass-ratio envelopes.

if nargin < 5 || strlength(string(family_name)) == 0
    family_name = "nominal";
end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [140 140 1100 720]);
ax = axes(fig);
hold(ax, 'on');

if isempty(overlay_table)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No pass-ratio overlay data found in current search domain', ...
        'domain_summary', sprintf('%s cross-profile overlay unavailable at h = %.0f km', char(string(semantic_mode)), h_km), ...
        'ylim', [0, 1.05], ...
        'plot_domain_source', "cross_profile_passratio"));
    title(ax, sprintf('%s sensor-group pass-ratio overlay at h = %.0f km', char(string(semantic_mode)), h_km));
    return;
end

groups = unique(overlay_table.sensor_group, 'stable');
cmap = lines(max(3, numel(groups)));
for idx = 1:numel(groups)
    sensor_group = groups(idx);
    sub = overlay_table(overlay_table.sensor_group == sensor_group, :);
    sub = sortrows(sub, 'Ns');
    valid = isfinite(sub.Ns) & isfinite(sub.overlay_pass_ratio);
    sub = sub(valid, :);
    if isempty(sub)
        continue;
    end
    label = char(local_group_label(sensor_group));
    if numel(unique(sub.Ns)) < 2
        plot(ax, sub.Ns, sub.overlay_pass_ratio, 'o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
            'MarkerFaceColor', cmap(idx, :), 'DisplayName', sprintf('%s (single point)', label));
    else
        plot(ax, sub.Ns, sub.overlay_pass_ratio, '-o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 7, ...
            'DisplayName', label);
    end
end

xlabel(ax, 'total satellites N_s');
ylabel(ax, 'max pass ratio over i');
title(ax, sprintf('%s sensor-group pass-ratio overlay at h = %.0f km [%s]', char(string(semantic_mode)), h_km, char(string(family_name))));
subtitle(ax, 'Each curve is the best-inclination envelope over the current search domain');
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'eastoutside');
set(ax, 'FontSize', 13);

diagnostic = local_saturation_note(summary_table);
apply_mb_plot_domain_guardrail(ax, overlay_table.Ns, overlay_table.overlay_pass_ratio, struct( ...
    'ylim', [0, 1.05], ...
    'plot_domain_source', "cross_profile_sensor_overlay", ...
    'domain_summary', char(diagnostic)));
if strlength(diagnostic) > 0
    text(ax, 0.02, 0.88, char(diagnostic), 'Units', 'normalized', ...
        'FontSize', 10, 'Color', [0.28 0.28 0.28], 'VerticalAlignment', 'top');
end
end

function label = local_group_label(sensor_group)
label = format_mb_sensor_group_label(char(string(sensor_group)), "short");
end

function note = local_saturation_note(summary_table)
note = "";
if isempty(summary_table) || ~ismember('right_plateau_reached', summary_table.Properties.VariableNames)
    return;
end
if numel(unique(summary_table.sensor_group)) < 2
    note = "single-group diagnostic only";
    return;
end
mask = ~summary_table.right_plateau_reached;
if any(mask)
    names = cellfun(@(s) char(format_mb_sensor_group_label(s, "short")), cellstr(summary_table.sensor_group(mask)), 'UniformOutput', false);
    note = "search domain may still be insufficient for full saturation: " + strjoin(names, ', ');
end
end
