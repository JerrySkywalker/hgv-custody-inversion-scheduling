function kappa2 = stage15_compute_pair_kernel(target_xy_km, sat1_xy_km, sat2_xy_km, box)
%STAGE15_COMPUTE_PAIR_KERNEL
% Minimal 2-satellite local geometry kernel.
%
% Inputs are 2D positions in km.

assert(numel(target_xy_km) == 2, 'target_xy_km must be [x,y].');
assert(numel(sat1_xy_km) == 2, 'sat1_xy_km must be [x,y].');
assert(numel(sat2_xy_km) == 2, 'sat2_xy_km must be [x,y].');

v1 = target_xy_km(:) - sat1_xy_km(:);
v2 = target_xy_km(:) - sat2_xy_km(:);

rho1 = norm(v1);
rho2 = norm(v2);

u1 = v1 / max(rho1, eps);
u2 = v2 / max(rho2, eps);

cosang = max(-1, min(1, dot(u1, u2)));
crossing_angle_deg = acosd(cosang);

G = [u1, u2] * [u1, u2]';
eigsG = eig(G);
lambda_min_geom = min(eigsG);

kappa2 = struct();
kappa2.rho1_norm = rho1 / max(box.half_span_km, eps);
kappa2.rho2_norm = rho2 / max(box.half_span_km, eps);
kappa2.crossing_angle_deg = crossing_angle_deg;
kappa2.lambda_min_geom = lambda_min_geom;
end
