function snap = debug_single_track_snapshot(track_i, cfg)
%DEBUG_SINGLE_TRACK_SNAPSHOT Build a CLI-friendly debug snapshot for one track.

if nargin < 2
    error('debug_single_track_snapshot:NotEnoughInputs', ...
        'track_i and cfg are required.');
end

target_cfg = build_target_cfg_from_track(track_i, cfg);
traj = propagate_single_track(target_cfg);

snap = struct();

snap.track_meta = struct();
snap.track_meta.traj_id = string(track_i.traj_id);
snap.track_meta.class_name = string(track_i.class_name);
snap.track_meta.bundle_id = string(track_i.bundle_id);
snap.track_meta.base_traj_id = string(track_i.base_traj_id);
snap.track_meta.variation_kind = string(track_i.variation_kind);

snap.track_payload = track_i.payload{1};
snap.target_init = target_cfg.init;
snap.target_reference = target_cfg.reference;
snap.target_dynamics = target_cfg.dynamics;
snap.target_control = target_cfg.control;
snap.target_control_profile = target_cfg.control_profile;

snap.consistency_checks = struct();
snap.consistency_checks.has_valid_anchor = ...
    ~(isnan(target_cfg.init.anchor_lat_deg) || isnan(target_cfg.init.anchor_lon_deg) || isnan(target_cfg.init.anchor_h_m));

snap.consistency_checks.has_valid_entry_point = ...
    isfield(target_cfg.init, 'entry_point_enu_km') && all(isfinite(target_cfg.init.entry_point_enu_km(:)));

snap.consistency_checks.enu_plot_available = ...
    isfield(traj, 'r_enu_km') && ~isempty(traj.r_enu_km) && ~any(isnan(traj.r_enu_km(:)));

snap.consistency_checks.ecef_plot_available = ...
    isfield(traj, 'r_ecef_km') && ~isempty(traj.r_ecef_km) && ~any(isnan(traj.r_ecef_km(:)));

snap.consistency_checks.local_geometry_mapped_to_geodetic = ...
    snap.consistency_checks.has_valid_anchor;

n_head = min(5, numel(traj.t_s));

snap.traj_head = struct();
snap.traj_head.t_s = traj.t_s(1:n_head);
snap.traj_head.lat_deg = traj.lat_deg(1:n_head);
snap.traj_head.lon_deg = traj.lon_deg(1:n_head);
snap.traj_head.h_km = traj.h_km(1:n_head);

if isfield(traj, 'r_ecef_km') && ~isempty(traj.r_ecef_km)
    snap.traj_head.r_ecef_km = traj.r_ecef_km(:,1:min(n_head,size(traj.r_ecef_km,2)));
else
    snap.traj_head.r_ecef_km = [];
end

if isfield(traj, 'r_enu_km') && ~isempty(traj.r_enu_km)
    snap.traj_head.r_enu_km = traj.r_enu_km(:,1:min(n_head,size(traj.r_enu_km,2)));
else
    snap.traj_head.r_enu_km = [];
end

snap.traj = traj;
end
