function eta = stage15_compute_target_local_summary_eta(target_state, box)
%STAGE15_COMPUTE_TARGET_LOCAL_SUMMARY_ETA
% Minimal short-horizon summary placeholder from current 3D state.
%
% target_state = [x_km, y_km, z_km, vx_mps, vy_mps, vz_mps]

assert(numel(target_state) == 6, ...
    'target_state must be [x_km, y_km, z_km, vx_mps, vy_mps, vz_mps].');

x_km = target_state(1);
y_km = target_state(2);
vx_mps = target_state(4);
vy_mps = target_state(5);
vz_mps = target_state(6);

dx_m = (x_km - box.center_xyz_km(1)) * 1000.0;
dy_m = (y_km - box.center_xyz_km(2)) * 1000.0;

rxy_m = hypot(dx_m, dy_m);
if rxy_m < eps
    radial_rate_mps = 0.0;
else
    radial_rate_mps = (dx_m * vx_mps + dy_m * vy_mps) / rxy_m;
end

eta = struct();
eta.radial_rate_norm = radial_rate_mps / max(box.velocity_ref_mps, eps);
eta.vertical_rate_norm = vz_mps / max(box.velocity_ref_mps, eps);
eta.turn_proxy = 0.0;
end
