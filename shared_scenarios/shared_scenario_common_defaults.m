function cfg = shared_scenario_common_defaults(base_cfg, overrides)
%SHARED_SCENARIO_COMMON_DEFAULTS Build shared scenario illustration config.

if nargin < 1 || isempty(base_cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(base_cfg);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

cfg.paths.shared_scenarios = fullfile(cfg.paths.root, 'output', 'shared_scenarios');

cfg.shared_scenarios = struct();
cfg.shared_scenarios.enable_auto_build = true;
cfg.shared_scenarios.scenario_id = 'baseline_ch4_ch5';
cfg.shared_scenarios.output_root = cfg.paths.shared_scenarios;
cfg.shared_scenarios.zone_center_lat_deg = cfg.geo.lat0_deg;
cfg.shared_scenarios.zone_center_lon_deg = cfg.geo.lon0_deg;
cfg.shared_scenarios.zone_radius_km = cfg.stage01.R_D_km;
cfg.shared_scenarios.representative_case_ids = ["N01", "H01_+00", "C1"];
cfg.shared_scenarios.baseline_theta = cfg.milestones.baseline_theta;
cfg.shared_scenarios.show_nominal_family = true;
cfg.shared_scenarios.show_heading_family = true;
cfg.shared_scenarios.show_critical_family = true;

cfg.shared_scenarios.SS1 = struct( ...
    'scenario_id', 'SS1', ...
    'title', 'defense_zone_2d');

cfg.shared_scenarios.SS2 = struct( ...
    'scenario_id', 'SS2', ...
    'title', 'earth_walker_zone_3d');

cfg = milestone_common_merge_structs(cfg, overrides);
end
