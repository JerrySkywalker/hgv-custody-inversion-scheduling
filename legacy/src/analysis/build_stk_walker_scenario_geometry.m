function geom = build_stk_walker_scenario_geometry(cfg)
%BUILD_STK_WALKER_SCENARIO_GEOMETRY Build SS2 geometry through STK-MATLAB.

cfg = shared_scenario_common_defaults(cfg);
availability = check_stk_matlab_availability(cfg);
if ~availability.is_available
    error('%s', availability.message);
end

stk_app = actxserver(char(availability.available_progid));
cleanup_app = onCleanup(@() local_close_stk(stk_app, cfg)); %#ok<NASGU>

try
    stk_app.NoGraphics = ~logical(cfg.shared_scenarios.stk.visible);
catch
end
try
    stk_app.ExecuteCommand('Unload / *');
catch
end

scenario_name = sprintf('%s_%s', cfg.shared_scenarios.stk.scenario_name, datestr(now, 'yyyymmdd_HHMMSS'));
start_time = local_format_stk_time(cfg.shared_scenarios.start_time);
stop_time = local_format_stk_time(cfg.shared_scenarios.stop_time);
stk_app.ExecuteCommand(sprintf('New / Scenario %s', scenario_name));
stk_app.ExecuteCommand(sprintf('SetTimePeriod * "%s" "%s"', ...
    start_time, stop_time));

cfg_walker = cfg;
cfg_walker.stage03.h_km = cfg.shared_scenarios.walker.altitude_km;
cfg_walker.stage03.i_deg = cfg.shared_scenarios.walker.inclination_deg;
cfg_walker.stage03.P = cfg.shared_scenarios.walker.geometry_planes;
cfg_walker.stage03.T = cfg.shared_scenarios.walker.total_satellites / cfg.shared_scenarios.walker.geometry_planes;
cfg_walker.stage03.F = cfg.shared_scenarios.walker.phasing;
walker = build_single_layer_walker_stage03(cfg_walker);

export_root = fullfile(cfg.shared_scenarios.stk.export_root, scenario_name);
ensure_dir(export_root);

sat_meta = repmat(struct('name', "", 'path', "", 'plane_id', [], 'sat_id_in_plane', [], 'states', table()), walker.Ns, 1);
semi_major_axis_m = cfg.shared_scenarios.earth_radius_m + cfg.shared_scenarios.walker.altitude_km * 1e3;
export_mode = "stk_report";
for k = 1:walker.Ns
    sat_info = walker.sat(k);
    sat_name = sprintf('%s_P%02dS%02d', cfg.shared_scenarios.stk.satellite_name_prefix, sat_info.plane_id, sat_info.sat_id_in_plane);
    stk_app.ExecuteCommand(sprintf('New / */Satellite %s', sat_name));
    setstate_cmd = sprintf(['SetState */Satellite/%s Classical %s "%s" "%s" %g %s "%s" ', ...
        '%.6f 0 %.6f 0 %.6f %.6f'], ...
        sat_name, ...
        cfg.shared_scenarios.stk.propagator, ...
        start_time, ...
        stop_time, ...
        cfg.shared_scenarios.sample_time_s, ...
        cfg.shared_scenarios.stk.coordinate_system, ...
        start_time, ...
        semi_major_axis_m, ...
        sat_info.i_deg, ...
        mod(sat_info.raan_deg + cfg.shared_scenarios.walker.raan_offset_deg, 360), ...
        mod(sat_info.M0_deg + cfg.shared_scenarios.walker.mean_anomaly_offset_deg, 360));
    stk_app.ExecuteCommand(setstate_cmd);

    sat_path = sprintf('*/Satellite/%s', sat_name);
    sat_meta(k).name = string(sat_name);
    sat_meta(k).path = string(sat_path);
    sat_meta(k).plane_id = sat_info.plane_id;
    sat_meta(k).sat_id_in_plane = sat_info.sat_id_in_plane;
    try
        export_out = stk_export_satellite_states(stk_app, sat_path, sat_name, cfg, export_root);
    catch
        export_mode = "fallback_stage03";
        sat_meta = local_build_fallback_states(walker, sat_meta, cfg);
        break;
    end

    sat_meta(k).states = export_out.table;
end

zone = build_defense_zone_surface_ring(cfg);
scenario_cases = build_shared_scenario_case_trajectories(cfg);
target_case = local_select_target_case(scenario_cases, cfg);

plane_tracks = local_build_plane_tracks(sat_meta, cfg);

geom = struct();
geom.backend = "stk_matlab";
geom.scenario_name = string(scenario_name);
geom.walker = walker;
geom.zone = zone;
geom.sat_meta = sat_meta;
geom.plane_tracks = plane_tracks;
geom.target_case = target_case;
geom.target_ecef_km = target_case.traj.r_ecef_km;
geom.scenario_cases = scenario_cases;
geom.export_root = string(export_root);
geom.earth_radius_km = cfg.shared_scenarios.earth_radius_m / 1000;
geom.export_mode = export_mode;
end

function plane_tracks = local_build_plane_tracks(sat_meta, cfg)
plane_ids = unique([sat_meta.plane_id], 'stable');
max_planes = min(cfg.shared_scenarios.render.max_orbit_planes_to_show, numel(plane_ids));
sample_idx = round(linspace(1, numel(plane_ids), max_planes));
planes_to_show = plane_ids(sample_idx);

plane_tracks = repmat(struct('plane_id', [], 'track_ecef_km', [], 'marker_ecef_km', []), numel(planes_to_show), 1);
for k = 1:numel(planes_to_show)
    pid = planes_to_show(k);
    sat_idx = find([sat_meta.plane_id] == pid);
    rep_idx = sat_idx(1);
    marker_count = min(cfg.shared_scenarios.render.max_satellites_per_plane_to_mark, numel(sat_idx));

    T = sat_meta(rep_idx).states;
    plane_tracks(k).plane_id = pid;
    plane_tracks(k).track_ecef_km = [T.x_km, T.y_km, T.z_km];

    markers = zeros(marker_count, 3);
    for j = 1:marker_count
        Tj = sat_meta(sat_idx(j)).states;
        markers(j, :) = [Tj.x_km(1), Tj.y_km(1), Tj.z_km(1)];
    end
    plane_tracks(k).marker_ecef_km = markers;
end
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
if ~isempty(scenario_cases.nominal)
    target_case = scenario_cases.nominal;
elseif ~isempty(scenario_cases.heading)
    target_case = scenario_cases.heading;
elseif ~isempty(scenario_cases.critical)
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

function local_close_stk(uiapp, cfg)
if ~cfg.shared_scenarios.stk.keep_open
    try
        uiapp.Terminate;
    catch
    end
end
end

function sat_meta = local_build_fallback_states(walker, sat_meta, cfg)
t_s = 0:cfg.shared_scenarios.sample_time_s:(seconds(datetime(cfg.shared_scenarios.stop_time) - datetime(cfg.shared_scenarios.start_time)));
satbank = propagate_constellation_stage03(walker, t_s);
for k = 1:walker.Ns
    sat_info = walker.sat(k);
    eci_km = squeeze(satbank.r_eci_km(:, :, k));
    ecef_m = eci_to_ecef(eci_km * 1000, cfg.time.epoch_utc, t_s(:));
    ecef_km = ecef_m / 1000;
    sat_meta(k).plane_id = sat_info.plane_id;
    sat_meta(k).sat_id_in_plane = sat_info.sat_id_in_plane;
    sat_meta(k).states = table(t_s(:), ecef_km(:, 1), ecef_km(:, 2), ecef_km(:, 3), ...
        'VariableNames', {'time_s', 'x_km', 'y_km', 'z_km'});
end
end

function txt = local_format_stk_time(value)
dt = datetime(value, 'TimeZone', 'UTC');
vec = datevec(dt);
month_names = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
txt = sprintf('%d %s %04d %02d:%02d:%05.2f', ...
    vec(3), month_names{vec(2)}, vec(1), vec(4), vec(5), vec(6));
end
