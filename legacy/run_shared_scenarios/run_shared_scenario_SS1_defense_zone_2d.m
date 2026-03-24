function out = run_shared_scenario_SS1_defense_zone_2d(cfg_override)
%RUN_SHARED_SCENARIO_SS1_DEFENSE_ZONE_2D Fast entry for shared scenario SS1.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = shared_scenario_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = shared_scenario_SS1_defense_zone_2d(cfg);
fprintf('[run_shared_scenarios] SS1 completed: %s\n', char(string(out.artifacts.summary_report)));
end
