function out = run_shared_scenario_SS2_earth_walker_zone_3d(cfg_override)
%RUN_SHARED_SCENARIO_SS2_EARTH_WALKER_ZONE_3D Fast entry for shared scenario SS2.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = shared_scenario_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = shared_scenario_SS2_earth_walker_zone_3d(cfg);
fprintf('[run_shared_scenarios] SS2 completed: %s\n', char(string(out.artifacts.summary_report)));
end
