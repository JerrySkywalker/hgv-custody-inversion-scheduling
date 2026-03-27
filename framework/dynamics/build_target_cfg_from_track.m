function target_cfg = build_target_cfg_from_track(track_i, cfg)
%BUILD_TARGET_CFG_FROM_TRACK Build per-track target propagation config.
%
%   target_cfg = BUILD_TARGET_CFG_FROM_TRACK(track_i, cfg)
%
%   Inputs:
%     - track_i : single-row task-set item table row
%     - cfg     : global config struct containing cfg.target_template

if nargin < 2
    error('build_target_cfg_from_track:NotEnoughInputs', ...
        'track_i and cfg are required.');
end

if ~istable(track_i) || height(track_i) ~= 1
    error('build_target_cfg_from_track:InvalidTrack', ...
        'track_i must be a single-row table.');
end

if ~isstruct(cfg) || ~isfield(cfg, 'target_template')
    error('build_target_cfg_from_track:MissingTargetTemplate', ...
        'cfg.target_template must exist.');
end

payload = track_i.payload{1};
tt = cfg.target_template;

target_cfg = struct();
target_cfg.track_id = string(track_i.traj_id);

target_cfg.init = struct();
target_cfg.init.scene_mode = get_payload_field(payload, 'scene_mode', 'local_disk');
target_cfg.init.anchor_lat_deg = get_payload_field(payload, 'anchor_lat_deg', NaN);
target_cfg.init.anchor_lon_deg = get_payload_field(payload, 'anchor_lon_deg', NaN);
target_cfg.init.anchor_h_m = get_payload_field(payload, 'anchor_h_m', NaN);

target_cfg.init.entry_theta_deg = get_payload_field(payload, 'entry_theta_deg', NaN);
target_cfg.init.heading_deg = get_payload_field(payload, 'heading_deg', NaN);
target_cfg.init.heading_offset_deg = get_payload_field(payload, 'heading_offset_deg', 0);

target_cfg.init.entry_point_xy_km = get_payload_field(payload, 'entry_point_xy_km', [NaN, NaN]);
target_cfg.init.entry_point_enu_km = get_payload_field(payload, 'entry_point_enu_km', [NaN, NaN]);
target_cfg.init.entry_point_enu_m = get_payload_field(payload, 'entry_point_enu_m', [NaN, NaN]);
target_cfg.init.heading_unit_xy = get_payload_field(payload, 'heading_unit_xy', [NaN, NaN]);
target_cfg.init.heading_unit_enu = get_payload_field(payload, 'heading_unit_enu', [NaN, NaN]);

target_cfg.dynamics = tt.dynamics;
target_cfg.control = tt.control;
target_cfg.constraints = tt.constraints;
target_cfg.reference = tt.reference;
target_cfg.planet = tt.planet;

% If reference anchor is available from track payload, override template defaults.
if ~isnan(target_cfg.init.anchor_lat_deg)
    target_cfg.reference.phi_ref_deg = target_cfg.init.anchor_lat_deg;
    target_cfg.reference.phi0_deg = target_cfg.init.anchor_lat_deg;
end
if ~isnan(target_cfg.init.anchor_lon_deg)
    target_cfg.reference.lambda_ref_deg = target_cfg.init.anchor_lon_deg;
    target_cfg.reference.lambda0_deg = target_cfg.init.anchor_lon_deg;
end

% Initialize heading from track when available.
if ~isnan(target_cfg.init.heading_deg)
    target_cfg.dynamics.sigma0_deg = target_cfg.init.heading_deg;
end
end

function value = get_payload_field(payload, field_name, default_value)
if isstruct(payload) && isfield(payload, field_name)
    value = payload.(field_name);
else
    value = default_value;
end
end
