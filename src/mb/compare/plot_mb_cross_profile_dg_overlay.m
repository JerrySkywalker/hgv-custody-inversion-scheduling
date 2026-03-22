function fig = plot_mb_cross_profile_dg_overlay(dg_table, summary_table, h_km, family_name, options)
%PLOT_MB_CROSS_PROFILE_DG_OVERLAY Plot cross-profile D_G envelopes across sensor groups.

if nargin < 4 || strlength(string(family_name)) == 0
    family_name = "nominal";
end
if nargin < 5 || isempty(options)
    options = struct();
end

fig = create_managed_figure(struct(), 'Color', 'w', 'Position', [180 180 1100 720]);
ax = axes(fig);
hold(ax, 'on');

value_field = char(string(local_getfield_or(options, 'value_field', 'overlay_D_G_min')));
y_label = char(string(local_getfield_or(options, 'y_label', 'raw max D_G^{min} over i')));
title_prefix = char(string(local_getfield_or(options, 'title_prefix', 'legacyDG cross-profile raw D_G envelope')));
note_override = string(local_getfield_or(options, 'note_override', ""));

if isempty(dg_table)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No D_G envelope summary found in current search domain', ...
        'domain_summary', sprintf('legacyDG cross-profile D_G overlay unavailable at h = %.0f km', h_km), ...
        'plot_domain_source', "cross_profile_DG"));
    title(ax, sprintf('legacyDG cross-profile D_G envelope at h = %.0f km', h_km));
    return;
end

groups = unique(dg_table.sensor_group, 'stable');
cmap = lines(max(3, numel(groups)));
for idx = 1:numel(groups)
    sensor_group = groups(idx);
    sub = dg_table(dg_table.sensor_group == sensor_group, :);
    sub = sortrows(sub, 'Ns');
    if ~ismember(value_field, sub.Properties.VariableNames)
        continue;
    end
    if isempty(sub)
        continue;
    end
    label = char(format_mb_sensor_group_label(char(string(sensor_group)), "short"));
    if numel(unique(sub.Ns)) < 2
        plot(ax, sub.Ns, sub.(value_field), 'o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
            'MarkerFaceColor', cmap(idx, :), 'DisplayName', sprintf('%s (single point)', label));
    else
        plot(ax, sub.Ns, sub.(value_field), '-o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 7, ...
            'DisplayName', label);
    end
end

xlabel(ax, 'total satellites N_s');
ylabel(ax, y_label);
title(ax, sprintf('%s at h = %.0f km [%s]', title_prefix, h_km, char(string(family_name))));
subtitle(ax, 'Best-inclination D_G envelope for strict reference and current sensor groups');
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'eastoutside');
set(ax, 'FontSize', 13);

note = note_override;
if strlength(note) == 0
    note = local_dg_note(summary_table, value_field);
end
apply_mb_plot_domain_guardrail(ax, dg_table.Ns, dg_table.(value_field), struct( ...
    'auto_ylim', true, ...
    'plot_domain_source', "cross_profile_DG", ...
    'domain_summary', char(note)));
if strlength(note) > 0
    text(ax, 0.02, 0.90, char(note), 'Units', 'normalized', ...
        'FontSize', 10, 'Color', [0.28 0.28 0.28], 'VerticalAlignment', 'top');
end
end

function note = local_dg_note(summary_table, value_field)
note = "";
if isempty(summary_table) || ~ismember('right_plateau_reached', summary_table.Properties.VariableNames)
    return;
end
if numel(unique(summary_table.sensor_group)) < 2
    note = "diag: single-group only";
    return;
end
mask = ~summary_table.right_plateau_reached;
if any(mask)
    note = "diag: DG envelope unsaturated";
elseif strcmp(value_field, 'overlay_D_G_min_normalized')
    note = "normalized DG candidate";
else
    note = "raw DG envelope";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
