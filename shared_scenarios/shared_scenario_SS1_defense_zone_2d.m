function result = shared_scenario_SS1_defense_zone_2d(cfg)
%SHARED_SCENARIO_SS1_DEFENSE_ZONE_2D Shared scenario SS1 placeholder.

startup();

if nargin < 1 || isempty(cfg)
    cfg = shared_scenario_common_defaults();
else
    cfg = shared_scenario_common_defaults(cfg);
end

meta = cfg.shared_scenarios.SS1;
paths = shared_scenario_common_output_paths(cfg, meta.scenario_id, meta.title);

result = struct();
result.scenario_id = meta.scenario_id;
result.title = meta.title;
result.config = cfg;
result.summary = struct('status', "skeleton_ready");
result.figures = struct();
result.artifacts = struct();
result.artifacts.summary_report = string(paths.summary_report);
result.artifacts.summary_mat = string(paths.summary_mat);
end
