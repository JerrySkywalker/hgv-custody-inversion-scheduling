function artifacts = export_mb_closedd_outputs(run_output, paths)
%EXPORT_MB_CLOSEDD_OUTPUTS Export closedD semantic outputs under MB layout.

if nargin < 2 || isempty(paths)
    error('export_mb_closedd_outputs requires run_output and paths.');
end

style = milestone_common_plot_style();
sensor_group = char(string(run_output.sensor_group.name));
sensor_label = char(string(run_output.sensor_group.sensor_label));

artifacts = struct();
artifacts.tables = struct();
artifacts.figures = struct();

summary_table = local_build_summary_table(run_output);
summary_csv = fullfile(paths.tables, sprintf('MB_closedD_summary_%s.csv', sensor_group));
milestone_common_save_table(summary_table, summary_csv);
artifacts.tables.summary = string(summary_csv);

for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    h_label = sprintf('h%d', round(run.h_km));

    pass_csv = fullfile(paths.tables, sprintf('MB_closedD_passratio_%s_%s.csv', h_label, sensor_group));
    heat_csv = fullfile(paths.tables, sprintf('MB_closedD_minimumNs_heatmap_iP_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(run.aggregate.passratio_phasecurve, pass_csv);
    milestone_common_save_table(run.aggregate.requirement_surface_iP.surface_table, heat_csv);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_csv);

    fig_pass = plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, struct());
    local_retitle(fig_pass, sprintf('closedD Pass-Ratio Profile versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_png = fullfile(paths.figures, sprintf('MB_closedD_passratio_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);

    fig_heat = plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style);
    local_retitle(fig_heat, sprintf('closedD Minimum Feasible Constellation Requirement over (i, P) at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_png = fullfile(paths.figures, sprintf('MB_closedD_minimumNs_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat, heat_png);
    close(fig_heat);

    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_png);
end
end

function summary_table = local_build_summary_table(run_output)
summary_table = table('Size', [numel(run_output.runs), 7], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'h_km', 'design_count', 'feasible_count', 'minimum_feasible_Ns', 'family_name'});
for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    summary_table(idx, :) = { ...
        "closedD", ...
        string(run_output.sensor_group.name), ...
        run.h_km, ...
        height(run.design_table), ...
        height(run.feasible_table), ...
        local_getfield_or(run.summary, 'minimum_feasible_Ns', missing), ...
        string(run.family_name)};
end
end

function local_retitle(fig, title_text)
ax = get(fig, 'CurrentAxes');
if isempty(ax)
    ax = axes(fig);
end
title(ax, title_text);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
