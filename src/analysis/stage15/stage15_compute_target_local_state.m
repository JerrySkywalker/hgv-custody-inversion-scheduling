function xi = stage15_compute_target_local_state(target_state, box)
%STAGE15_COMPUTE_TARGET_LOCAL_STATE
% target_state = [x_km, y_km, vx_mps, vy_mps]

assert(numel(target_state) == 4, 'target_state must be [x_km, y_km, vx_mps, vy_mps].');

x_km = target_state(1);
y_km = target_state(2);
vx_mps = target_state(3);
vy_mps = target_state(4);

dx = x_km - box.center_xy_km(1);
dy = y_km - box.center_xy_km(2);

r_km = hypot(dx, dy);
bearing_rad = atan2(dy, dx);
heading_rad = atan2(vy_mps, vx_mps);
speed_mps = hypot(vx_mps, vy_mps);

xi = struct();
xi.r_norm = r_km / max(box.half_span_km, eps);
xi.bearing_rad = bearing_rad;
xi.heading_rad = heading_rad;
xi.speed_norm = speed_mps / max(box.velocity_ref_mps, eps);
end
