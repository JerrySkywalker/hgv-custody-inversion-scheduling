function artifacts = export_mb_semantic_dense_local_outputs(local_out, paths)
%EXPORT_MB_SEMANTIC_DENSE_LOCAL_OUTPUTS Export dense local semantic comparison artifacts.

style = milestone_common_plot_style();
sensor_group = char(string(local_out.sensor_group));
anchor_h_label = sprintf('h%d', round(local_out.anchor_h_km));

artifacts = struct();
artifacts.tables = struct();
artifacts.figures = struct();

summary_csv = fullfile(paths.tables, sprintf('MB_denseLocal_summary_%s.csv', sensor_group));
milestone_common_save_table(local_build_summary_table(local_out.summary), summary_csv);
artifacts.tables.summary = string(summary_csv);

legacy_hi_csv = fullfile(paths.tables, sprintf('MB_legacyDG_denseLocal_requirement_hi_%s.csv', sensor_group));
closed_hi_csv = fullfile(paths.tables, sprintf('MB_closedD_denseLocal_requirement_hi_%s.csv', sensor_group));
milestone_common_save_table(local_out.legacy_requirement_surface_hi.surface_table, legacy_hi_csv);
milestone_common_save_table(local_out.closed_requirement_surface_hi.surface_table, closed_hi_csv);
artifacts.tables.legacy_requirement_hi = string(legacy_hi_csv);
artifacts.tables.closed_requirement_hi = string(closed_hi_csv);

fig_hi_legacy = plot_mb_requirement_heatmap_hi(local_out.legacy_requirement_surface_hi, table(), style);
local_retitle(fig_hi_legacy, sprintf('legacyDG Dense Local Requirement over (h, i) [%s]', sensor_group));
legacy_hi_png = fullfile(paths.figures, sprintf('MB_legacyDG_denseLocal_requirement_hi_%s.png', sensor_group));
milestone_common_save_figure(fig_hi_legacy, legacy_hi_png);
close(fig_hi_legacy);

fig_hi_closed = plot_mb_requirement_heatmap_hi(local_out.closed_requirement_surface_hi, table(), style);
local_retitle(fig_hi_closed, sprintf('closedD Dense Local Requirement over (h, i) [%s]', sensor_group));
closed_hi_png = fullfile(paths.figures, sprintf('MB_closedD_denseLocal_requirement_hi_%s.png', sensor_group));
milestone_common_save_figure(fig_hi_closed, closed_hi_png);
close(fig_hi_closed);

artifacts.figures.legacy_requirement_hi = string(legacy_hi_png);
artifacts.figures.closed_requirement_hi = string(closed_hi_png);

legacy_ip_csv = fullfile(paths.tables, sprintf('MB_legacyDG_denseLocal_minimumNs_heatmap_iP_%s_%s.csv', anchor_h_label, sensor_group));
closed_ip_csv = fullfile(paths.tables, sprintf('MB_closedD_denseLocal_minimumNs_heatmap_iP_%s_%s.csv', anchor_h_label, sensor_group));
gap_ip_csv = fullfile(paths.tables, sprintf('MB_comparison_denseLocal_gap_heatmap_iP_%s_%s.csv', anchor_h_label, sensor_group));
legacy_pass_csv = fullfile(paths.tables, sprintf('MB_legacyDG_denseLocal_passratio_%s_%s.csv', anchor_h_label, sensor_group));
closed_pass_csv = fullfile(paths.tables, sprintf('MB_closedD_denseLocal_passratio_%s_%s.csv', anchor_h_label, sensor_group));
frontier_shift_csv = fullfile(paths.tables, sprintf('MB_comparison_denseLocal_frontier_shift_%s_%s.csv', anchor_h_label, sensor_group));
milestone_common_save_table(local_out.anchor_legacy_run.aggregate.requirement_surface_iP.surface_table, legacy_ip_csv);
milestone_common_save_table(local_out.anchor_closed_run.aggregate.requirement_surface_iP.surface_table, closed_ip_csv);
milestone_common_save_table(local_out.anchor_gap_pair.requirement_gap_table, gap_ip_csv);
milestone_common_save_table(local_out.anchor_legacy_run.aggregate.passratio_phasecurve, legacy_pass_csv);
milestone_common_save_table(local_out.anchor_closed_run.aggregate.passratio_phasecurve, closed_pass_csv);
milestone_common_save_table(local_out.anchor_gap_pair.frontier_gap_table, frontier_shift_csv);

fig_ip_legacy = plot_mb_fixed_h_requirement_heatmap_iP(local_out.anchor_legacy_run.aggregate.requirement_surface_iP, style);
local_retitle(fig_ip_legacy, sprintf('legacyDG Dense Local Minimum Feasible Requirement at h = %.0f km [%s]', local_out.anchor_h_km, sensor_group));
legacy_ip_png = fullfile(paths.figures, sprintf('MB_legacyDG_denseLocal_minimumNs_heatmap_iP_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_ip_legacy, legacy_ip_png);
close(fig_ip_legacy);

fig_ip_closed = plot_mb_fixed_h_requirement_heatmap_iP(local_out.anchor_closed_run.aggregate.requirement_surface_iP, style);
local_retitle(fig_ip_closed, sprintf('closedD Dense Local Minimum Feasible Requirement at h = %.0f km [%s]', local_out.anchor_h_km, sensor_group));
closed_ip_png = fullfile(paths.figures, sprintf('MB_closedD_denseLocal_minimumNs_heatmap_iP_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_ip_closed, closed_ip_png);
close(fig_ip_closed);

fig_gap = plot_semantic_gap_heatmap(local_out.anchor_gap_pair.requirement_gap_table, local_out.anchor_h_km, sensor_group);
gap_ip_png = fullfile(paths.figures, sprintf('MB_comparison_denseLocal_gap_heatmap_iP_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_gap, gap_ip_png);
close(fig_gap);

fig_pass_legacy = plot_mb_fixed_h_passratio_phasecurve(local_out.anchor_legacy_run.aggregate.passratio_phasecurve, local_out.anchor_h_km, style, struct());
local_retitle(fig_pass_legacy, sprintf('legacyDG Dense Local Pass-Ratio at h = %.0f km [%s]', local_out.anchor_h_km, sensor_group));
legacy_pass_png = fullfile(paths.figures, sprintf('MB_legacyDG_denseLocal_passratio_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_pass_legacy, legacy_pass_png);
close(fig_pass_legacy);

fig_pass_closed = plot_mb_fixed_h_passratio_phasecurve(local_out.anchor_closed_run.aggregate.passratio_phasecurve, local_out.anchor_h_km, style, struct());
local_retitle(fig_pass_closed, sprintf('closedD Dense Local Pass-Ratio at h = %.0f km [%s]', local_out.anchor_h_km, sensor_group));
closed_pass_png = fullfile(paths.figures, sprintf('MB_closedD_denseLocal_passratio_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_pass_closed, closed_pass_png);
close(fig_pass_closed);

fig_frontier = plot_semantic_gap_frontier_shift(local_out.anchor_gap_pair.frontier_gap_table, local_out.anchor_h_km, sensor_group);
frontier_shift_png = fullfile(paths.figures, sprintf('MB_comparison_denseLocal_frontier_shift_%s_%s.png', anchor_h_label, sensor_group));
milestone_common_save_figure(fig_frontier, frontier_shift_png);
close(fig_frontier);

artifacts.tables.legacy_requirement_iP = string(legacy_ip_csv);
artifacts.tables.closed_requirement_iP = string(closed_ip_csv);
artifacts.tables.gap_requirement_iP = string(gap_ip_csv);
artifacts.tables.legacy_passratio = string(legacy_pass_csv);
artifacts.tables.closed_passratio = string(closed_pass_csv);
artifacts.tables.frontier_shift = string(frontier_shift_csv);
artifacts.figures.legacy_requirement_iP = string(legacy_ip_png);
artifacts.figures.closed_requirement_iP = string(closed_ip_png);
artifacts.figures.gap_requirement_iP = string(gap_ip_png);
artifacts.figures.legacy_passratio = string(legacy_pass_png);
artifacts.figures.closed_passratio = string(closed_pass_png);
artifacts.figures.frontier_shift = string(frontier_shift_png);
end

function local_retitle(fig, title_text)
ax = get(fig, 'CurrentAxes');
if isempty(ax)
    ax = axes(fig);
end
title(ax, title_text);
end

function summary_table = local_build_summary_table(summary)
names = fieldnames(summary);
values = strings(numel(names), 1);
for idx = 1:numel(names)
    values(idx) = string(local_stringify(summary.(names{idx})));
end
summary_table = table(string(names), values, 'VariableNames', {'field', 'value'});
end

function txt = local_stringify(value)
if ismissing(value)
    if isscalar(value)
        txt = "<missing>";
    else
        txt = mat2str(string(value));
    end
elseif isnumeric(value) || islogical(value)
    if isscalar(value)
        txt = char(string(value));
    else
        txt = mat2str(value);
    end
elseif isstring(value) || ischar(value)
    txt = char(string(value));
elseif iscell(value)
    txt = strjoin(cellstr(string(value)), ', ');
else
    txt = char(string(value));
end
end
