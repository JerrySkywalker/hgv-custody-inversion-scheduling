function geom = build_walker_scenario_geometry(cfg)
%BUILD_WALKER_SCENARIO_GEOMETRY Build shared scenario geometry from walkerDelta backend.

cfg = shared_scenario_common_defaults(cfg);
availability = check_walkerDelta_availability();
if ~availability.is_available
    error('%s', availability.message);
end

start_time = datetime(cfg.shared_scenarios.start_time, 'TimeZone', 'UTC');
stop_time = datetime(cfg.shared_scenarios.stop_time, 'TimeZone', 'UTC');
sample_time_s = cfg.shared_scenarios.sample_time_s;

sc = satelliteScenario(start_time, stop_time, sample_time_s);

walker_cfg = cfg.shared_scenarios.walker;
radius_m = cfg.shared_scenarios.earth_radius_m + walker_cfg.altitude_km * 1e3;
sat = walkerDelta(sc, radius_m, walker_cfg.inclination_deg, walker_cfg.total_satellites, ...
    walker_cfg.geometry_planes, walker_cfg.phasing, ...
    RAAN=walker_cfg.raan_deg, ...
    ArgumentOfLatitude=walker_cfg.argument_of_latitude_deg, ...
    Name=walker_cfg.name, ...
    OrbitPropagator=walker_cfg.orbit_propagator);

zone = build_defense_zone_surface_ring(cfg);
tracks = extract_walker_tracks_from_scenario(sc, sat, cfg);
scenario_cases = build_shared_scenario_case_trajectories(cfg);
target_case = local_select_target_case(scenario_cases, cfg);

target_ecef_m = [];
target_projected_km = [];
if ~isempty(target_case)
    target_ecef_m = target_case.traj.r_ecef_m;
    target_projected_km = project_case_trajectory_to_local_plane(target_ecef_m, zone);
end

geom = struct();
geom.backend = "walkerDelta";
geom.scenario = sc;
geom.sat = sat;
geom.walker = walker_cfg;
geom.zone = zone;
geom.tracks = tracks;
geom.target_case = target_case;
geom.target_ecef_m = target_ecef_m;
geom.target_ecef_km = target_ecef_m / 1000;
geom.target_projected_km = target_projected_km;
geom.scenario_cases = scenario_cases;
geom.earth_radius_km = cfg.shared_scenarios.earth_radius_m / 1000;
end

function target_case = local_select_target_case(scenario_cases, cfg)
target_case = struct([]);
ids = string(cfg.shared_scenarios.representative_case_ids);
for k = 1:numel(ids)
    item = local_find_case_by_id(scenario_cases.all, ids(k));
    if ~isempty(item)
        target_case = item;
        return;
    end
end

if cfg.shared_scenarios.show_nominal_family && ~isempty(scenario_cases.nominal)
    target_case = scenario_cases.nominal;
elseif cfg.shared_scenarios.show_heading_family && ~isempty(scenario_cases.heading)
    target_case = scenario_cases.heading;
elseif cfg.shared_scenarios.show_critical_family && ~isempty(scenario_cases.critical)
    target_case = scenario_cases.critical;
end
end

function item = local_find_case_by_id(all_cases, case_id)
item = struct([]);
for k = 1:numel(all_cases)
    if strcmpi(string(all_cases(k).case.case_id), string(case_id))
        item = all_cases(k);
        return;
    end
end
end
