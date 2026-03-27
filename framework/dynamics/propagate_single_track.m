function traj = propagate_single_track(target_cfg)
%PROPAGATE_SINGLE_TRACK Propagate one target trajectory from target_cfg.

if nargin < 1 || ~isstruct(target_cfg)
    error('propagate_single_track:InvalidInput', ...
        'target_cfg must be a struct.');
end

Re = target_cfg.planet.re_m;

X0 = [ ...
    target_cfg.init.v0_mps, ...
    target_cfg.init.theta0_rad, ...
    target_cfg.init.sigma0_rad, ...
    target_cfg.init.phi0_rad, ...
    target_cfg.init.lambda0_rad, ...
    Re + target_cfg.init.h0_m ]';

t0 = target_cfg.dynamics.t0_s;
tf = target_cfg.dynamics.tmax_s;

opts = odeset('RelTol',1e-6, 'AbsTol',1e-6, ...
    'Events', @(t,X) hgv_events(t, X, target_cfg, struct('Re', Re)));

[T, X] = ode45(@(t,X) eval_dynamics_model(t, X, target_cfg), [t0 tf], X0, opts);

t_uniform = (t0 : target_cfg.dynamics.ts_s : T(end))';
X_uniform = interp1(T, X, t_uniform, 'linear');

v_mps   = X_uniform(:,1);
phi_rad = X_uniform(:,4);
lam_rad = X_uniform(:,5);
r_m     = X_uniform(:,6);

lat_deg = rad2deg(phi_rad);
lon_deg = rad2deg(lam_rad);
h_m     = r_m - Re;
h_km    = h_m / 1000;

r_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, target_cfg).';
r_ecef_km = r_ecef_m / 1000;

r_enu_m = ecef_to_local_enu( ...
    r_ecef_m, ...
    target_cfg.init.anchor_lat_deg, ...
    target_cfg.init.anchor_lon_deg, ...
    target_cfg.init.anchor_h_m, ...
    target_cfg);
r_enu_km = r_enu_m / 1000;

traj = struct();
traj.track_id = target_cfg.track_id;
traj.target_cfg = target_cfg;

traj.t_s = t_uniform;
traj.state_hist = X_uniform;

traj.v_mps = v_mps;
traj.lat_deg = lat_deg;
traj.lon_deg = lon_deg;
traj.h_m = h_m;
traj.h_km = h_km;

traj.r_ecef_m = r_ecef_m;
traj.r_ecef_km = r_ecef_km;
traj.r_enu_m = r_enu_m;
traj.r_enu_km = r_enu_km;
end
