function xi = stage15_compute_target_local_state_3d(target_state, box)
%STAGE15_COMPUTE_TARGET_LOCAL_STATE_3D
% target_state = [x_km, y_km, z_km, vx_mps, vy_mps, vz_mps]

assert(numel(target_state) == 6, ...
    'target_state must be [x_km, y_km, z_km, vx_mps, vy_mps, vz_mps].');

x_km = target_state(1);
y_km = target_state(2);
z_km = target_state(3);
vx_mps = target_state(4);
vy_mps = target_state(5);
vz_mps = target_state(6);

dx = x_km - box.center_xyz_km(1);
dy = y_km - box.center_xyz_km(2);
dz = z_km - box.center_xyz_km(3);

r_xy_km = hypot(dx, dy);
bearing_rad = atan2(dy, dx);
heading_xy_rad = atan2(vy_mps, vx_mps);
speed_mps = norm([vx_mps, vy_mps, vz_mps]);

xi = struct();
xi.r_norm_xy = r_xy_km / max(box.half_span_km, eps);
xi.z_norm = dz / max(box.height_ref_km, eps);
xi.bearing_rad = bearing_rad;
xi.heading_xy_rad = heading_xy_rad;
xi.speed_norm = speed_mps / max(box.velocity_ref_mps, eps);
end
