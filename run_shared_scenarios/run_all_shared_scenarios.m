function outputs = run_all_shared_scenarios(cfg_override)
%RUN_ALL_SHARED_SCENARIOS Run all shared dissertation scenario illustrations.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = shared_scenario_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

outputs = struct();
outputs.SS1 = shared_scenario_SS1_defense_zone_2d(cfg);
outputs.SS2 = shared_scenario_SS2_earth_walker_zone_3d(cfg);
fprintf('[run_shared_scenarios] Completed SS1 and SS2 shared scenario packages.\n');
end
