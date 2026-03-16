function result = shared_scenario_SS1_defense_zone_2d(cfg)
%SHARED_SCENARIO_SS1_DEFENSE_ZONE_2D Shared 2D defense-zone explanation package.

startup();

if nargin < 1 || isempty(cfg)
    cfg = shared_scenario_common_defaults();
else
    cfg = shared_scenario_common_defaults(cfg);
end

meta = cfg.shared_scenarios.SS1;
paths = shared_scenario_common_output_paths(cfg, meta.scenario_id, meta.title);
style = milestone_common_plot_style();
geom = build_shared_scenario_geometry(cfg);
scenario_cases = build_shared_scenario_case_trajectories(cfg);

fig = plot_defense_zone_2d(geom, scenario_cases, style);
fig_path = fullfile(paths.figures, 'SS1_defense_zone_2d_overview.png');
milestone_common_save_figure(fig, fig_path);
close(fig);

result = local_build_result(cfg, meta, fig_path, scenario_cases, paths);
save(paths.summary_mat, 'result', '-v7.3');
local_write_report(paths.summary_report, result);
result.artifacts.summary_report = string(paths.summary_report);
result.artifacts.summary_mat = string(paths.summary_mat);
end

function result = local_build_result(cfg, meta, fig_path, scenario_cases, paths)
result = struct();
result.scenario_id = meta.scenario_id;
result.title = meta.title;
result.config = cfg;
result.figures = struct('defense_zone_2d_overview', string(fig_path));
result.artifacts = struct('scenario_output_root', string(paths.scenario_root));
result.summary = struct( ...
    'zone_radius_km', cfg.shared_scenarios.zone_radius_km, ...
    'zone_center_lat_deg', cfg.shared_scenarios.zone_center_lat_deg, ...
    'zone_center_lon_deg', cfg.shared_scenarios.zone_center_lon_deg, ...
    'nominal_case', local_case_id(scenario_cases.nominal), ...
    'heading_case', local_case_id(scenario_cases.heading), ...
    'critical_case', local_case_id(scenario_cases.critical));
end

function local_write_report(file_path, result)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open SS1 report: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# SS1 defense zone 2D\n\n');
fprintf(fid, '## Purpose\n\n第四章与第五章共用的二维防区说明图。\n\n');
fprintf(fid, '## Outputs\n\n');
fprintf(fid, '- figure: `%s`\n\n', result.figures.defense_zone_2d_overview);
fprintf(fid, '## Summary\n\n');
fprintf(fid, '- zone radius: `%g km`\n', result.summary.zone_radius_km);
fprintf(fid, '- zone center: `(%g deg, %g deg)`\n', result.summary.zone_center_lat_deg, result.summary.zone_center_lon_deg);
fprintf(fid, '- representative cases: `%s`, `%s`, `%s`\n', result.summary.nominal_case, result.summary.heading_case, result.summary.critical_case);
end

function case_id = local_case_id(item)
if isempty(item)
    case_id = "";
else
    case_id = string(item.case.case_id);
end
end
