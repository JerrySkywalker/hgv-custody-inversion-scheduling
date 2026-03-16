function result = shared_scenario_SS2_earth_walker_zone_3d(cfg)
%SHARED_SCENARIO_SS2_EARTH_WALKER_ZONE_3D Shared 3D Earth/Walker/zone package.

startup();

if nargin < 1 || isempty(cfg)
    cfg = shared_scenario_common_defaults();
else
    cfg = shared_scenario_common_defaults(cfg);
end

meta = cfg.shared_scenarios.SS2;
paths = shared_scenario_common_output_paths(cfg, meta.scenario_id, meta.title);
style = milestone_common_plot_style();
geom = build_walker_scenario_geometry(cfg);

result = struct();
result.scenario_id = meta.scenario_id;
result.title = meta.title;
result.config = cfg;
fig = render_ss2_earth_walker_zone_3d(geom, cfg, style);
fig_path = fullfile(paths.figures, 'SS2_earth_walker_defense_zone_3d.png');
milestone_common_save_figure(fig, fig_path);
close(fig);

result.summary = struct( ...
    'backend', geom.backend, ...
    'zone_radius_km', cfg.shared_scenarios.zone.radius_km, ...
    'baseline_theta', cfg.shared_scenarios.baseline_theta, ...
    'num_satellites', cfg.shared_scenarios.walker.total_satellites, ...
    'representative_case', local_case_id(geom.target_case));
result.figures = struct('earth_walker_defense_zone_3d', string(fig_path));
result.artifacts = struct('scenario_output_root', string(paths.scenario_root));

save(paths.summary_mat, 'result', '-v7.3');
local_write_report(paths.summary_report, result);
result.artifacts.summary_report = string(paths.summary_report);
result.artifacts.summary_mat = string(paths.summary_mat);
end

function local_write_report(file_path, result)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open SS2 report: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# SS2 earth walker zone 3D\n\n');
fprintf(fid, '## Purpose\n\n第四章与第五章共用的 Earth / Walker / 防区空间关系图。\n\n');
fprintf(fid, '## Outputs\n\n');
fprintf(fid, '- figure: `%s`\n\n', result.figures.earth_walker_defense_zone_3d);
fprintf(fid, '## Summary\n\n');
fprintf(fid, '- zone radius: `%g km`\n', result.summary.zone_radius_km);
fprintf(fid, '- number of satellites: `%g`\n', result.summary.num_satellites);
fprintf(fid, '- representative target case: `%s`\n', result.summary.representative_case);
end

function case_id = local_case_id(item)
if isempty(item)
    case_id = "";
else
    case_id = string(item.case.case_id);
end
end
