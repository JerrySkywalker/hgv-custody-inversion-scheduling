function fig = plot_mb_cross_profile_passratio_overlay(overlay_table, summary_table, h_km, semantic_mode, family_name, options)
%PLOT_MB_CROSS_PROFILE_PASSRATIO_OVERLAY Plot sensor-group overlays of pass-ratio envelopes.

if nargin < 5 || strlength(string(family_name)) == 0
    family_name = "nominal";
end
if nargin < 6 || isempty(options)
    options = struct();
end

fig = create_managed_figure(struct(), 'Color', 'w', 'Position', [140 140 1100 720]);
ax = axes(fig);
hold(ax, 'on');
contract = local_getfield_or(options, 'plot_view_contract', struct());

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
base_grid_step = local_resolve_base_grid_step(overlay_table);
gap_steps_for_break = max(1, double(local_getfield_or(options, 'passratio_gap_steps_for_break', 1)));
max_gap_for_connect = inf;
if isstruct(contract) && isfield(contract, 'view_name') && string(contract.view_name) ~= "historyFull" && isfinite(base_grid_step)
    max_gap_for_connect = gap_steps_for_break * base_grid_step;
end
for idx = 1:numel(groups)
    sensor_group = groups(idx);
    sub = overlay_table(overlay_table.sensor_group == sensor_group, :);
    sub = sortrows(sub, 'Ns');
    label = char(local_group_label(sensor_group));
    is_defined = isfinite(sub.overlay_pass_ratio);
    segments = build_mb_polyline_segments_from_defined_points(sub.Ns, sub.overlay_pass_ratio, is_defined, max_gap_for_connect);
    display_consumed = false;
    for idx_seg = 1:numel(segments)
        seg = segments{idx_seg};
        if numel(seg.x) < 2
            plot(ax, seg.x, seg.y, 'o', ...
                'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
                'MarkerFaceColor', cmap(idx, :), 'DisplayName', local_segment_label(label + " (isolated)", display_consumed));
        else
            plot(ax, seg.x, seg.y, '-o', ...
                'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 7, ...
                'DisplayName', local_segment_label(label, display_consumed));
        end
        display_consumed = true;
    end
end

xlabel(ax, 'total satellites N_s');
ylabel(ax, 'max pass ratio over i');
title(ax, sprintf('%s sensor-group pass-ratio overlay at h = %.0f km [%s]', char(string(semantic_mode)), h_km, char(string(family_name))));
subtitle(ax, char(local_getfield_or(options, 'subtitle_text', "Each curve is the best-inclination envelope over the current search domain")));
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'eastoutside');
set(ax, 'FontSize', 13);

diagnostic = local_saturation_note(summary_table);
plot_xlim = local_getfield_or(options, 'plot_xlim_ns', []);
if isnumeric(plot_xlim) && numel(plot_xlim) == 2 && all(isfinite(plot_xlim))
    xlim(ax, plot_xlim);
end
apply_mb_plot_domain_guardrail(ax, overlay_table.Ns, overlay_table.overlay_pass_ratio, struct( ...
    'plot_xlim_ns', plot_xlim, ...
    'ylim', [0, 1.05], ...
    'plot_domain_source', string(local_getfield_or(options, 'plot_domain_label', "cross_profile_sensor_overlay")), ...
    'domain_summary', char(diagnostic)));
if strlength(diagnostic) > 0
    text(ax, 0.02, 0.88, char(diagnostic), 'Units', 'normalized', ...
        'FontSize', 10, 'Color', [0.28 0.28 0.28], 'VerticalAlignment', 'top');
end
scope_text = string(local_getfield_or(options, 'scope_annotation_text', ""));
if strlength(scope_text) > 0
    text(ax, 0.02, 0.80, char(scope_text), 'Units', 'normalized', ...
        'FontSize', 10, 'Color', [0.28 0.28 0.28], 'VerticalAlignment', 'top');
end
end

function label = local_segment_label(base_label, consumed)
if consumed
    label = "";
else
    label = base_label;
end
end

function label = local_group_label(sensor_group)
sensor_group = string(sensor_group);
if ismissing(sensor_group) || strlength(sensor_group) == 0
    label = "unlabeled";
    return;
end
label = format_mb_sensor_group_label(char(sensor_group), "short");
end

function note = local_saturation_note(summary_table)
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
    note = "diag: overlay unsaturated";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function step = local_resolve_base_grid_step(T)
step = NaN;
if istable(T) && ismember('base_grid_step', T.Properties.VariableNames)
    values = T.base_grid_step(isfinite(T.base_grid_step));
    if ~isempty(values)
        step = values(1);
        return;
    end
end
if istable(T) && ismember('Ns', T.Properties.VariableNames)
    ns_values = unique(T.Ns(isfinite(T.Ns)), 'sorted');
    if numel(ns_values) >= 2
        step = min(diff(ns_values));
    end
end
end
