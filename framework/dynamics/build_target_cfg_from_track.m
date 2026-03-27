function target_cfg = build_target_cfg_from_track(track_i, cfg)
%BUILD_TARGET_CFG_FROM_TRACK Build per-track target propagation config.
%
%   target_cfg = BUILD_TARGET_CFG_FROM_TRACK(track_i, cfg)

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
if isfield(tt, 'atmosphere') && isstruct(tt.atmosphere)
    target_cfg.atmosphere = tt.atmosphere;
else
    target_cfg.atmosphere = struct('model_name', 'us76');
end
if isfield(tt, 'aero') && isstruct(tt.aero) && isstruct(tt.aero)
    target_cfg.aero = tt.aero;
else
    target_cfg.aero = struct();
end

% Carry over class / variation semantics into control context.
target_cfg.control.family = char(string(track_i.class_name));
target_cfg.control.subfamily = char(string(track_i.variation_kind));

if ~isnan(target_cfg.init.anchor_lat_deg)
    target_cfg.reference.phi_ref_deg = target_cfg.init.anchor_lat_deg;
    target_cfg.reference.phi0_deg = target_cfg.init.anchor_lat_deg;
end
if ~isnan(target_cfg.init.anchor_lon_deg)
    target_cfg.reference.lambda_ref_deg = target_cfg.init.anchor_lon_deg;
    target_cfg.reference.lambda0_deg = target_cfg.init.anchor_lon_deg;
end

target_cfg.init.v0_mps = target_cfg.dynamics.v0_mps;
target_cfg.init.h0_m = target_cfg.dynamics.h0_m;
target_cfg.init.theta0_rad = deg2rad(target_cfg.dynamics.theta0_deg);

if ~isnan(target_cfg.init.heading_deg)
    target_cfg.dynamics.sigma0_deg = target_cfg.init.heading_deg;
end
target_cfg.init.sigma0_rad = deg2rad(target_cfg.dynamics.sigma0_deg);
target_cfg.init.phi0_rad = deg2rad(target_cfg.reference.phi0_deg);
target_cfg.init.lambda0_rad = deg2rad(target_cfg.reference.lambda0_deg);

target_cfg.control_profile = build_control_profile(target_cfg);
end

function value = get_payload_field(payload, field_name, default_value)
if isstruct(payload) && isfield(payload, field_name)
    value = payload.(field_name);
else
    value = default_value;
end
end


