function tracks = extract_walker_tracks_from_scenario(sc, sat, cfg)
%EXTRACT_WALKER_TRACKS_FROM_SCENARIO Extract representative tracks from walkerDelta scenario.

cfg = shared_scenario_common_defaults(cfg);

[pos_ecef_m, ~, time_out] = states(sat, "CoordinateFrame", "ecef");
pos_ecef_km = permute(pos_ecef_m, [2, 1, 3]) / 1000;
n_sat = size(pos_ecef_km, 3);
sat_per_plane = cfg.shared_scenarios.walker.total_satellites / cfg.shared_scenarios.walker.geometry_planes;

if abs(sat_per_plane - round(sat_per_plane)) > 0
    error('Walker geometry requires total_satellites / geometry_planes to be an integer.');
end
sat_per_plane = round(sat_per_plane);

plane_ids = ceil((1:n_sat) / sat_per_plane);
unique_planes = unique(plane_ids, 'stable');
max_planes = min(cfg.shared_scenarios.render.max_orbit_planes_to_show, numel(unique_planes));
sample_plane_idx = round(linspace(1, numel(unique_planes), max_planes));
planes_to_show = unique_planes(sample_plane_idx);

plane_tracks = repmat(struct('plane_id', [], 'track_ecef_km', [], 'marker_ecef_km', []), numel(planes_to_show), 1);
for k = 1:numel(planes_to_show)
    plane_id = planes_to_show(k);
    sat_idx = find(plane_ids == plane_id);
    rep_sat = sat_idx(1);
    marker_count = min(cfg.shared_scenarios.render.max_satellites_per_plane_to_mark, numel(sat_idx));

    plane_tracks(k).plane_id = plane_id;
    plane_tracks(k).track_ecef_km = squeeze(pos_ecef_km(:, :, rep_sat));
    plane_tracks(k).marker_ecef_km = squeeze(pos_ecef_km(1, :, sat_idx(1:marker_count)));
end

tracks = struct();
tracks.time = time_out;
tracks.position_ecef_km = pos_ecef_km;
tracks.plane_ids = plane_ids;
tracks.planes_to_show = planes_to_show;
tracks.sat_per_plane = sat_per_plane;
tracks.plane_tracks = plane_tracks;
tracks.initial_positions_ecef_km = squeeze(pos_ecef_km(1, :, :)).';
end
