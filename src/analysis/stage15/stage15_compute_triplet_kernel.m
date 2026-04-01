function kappa3 = stage15_compute_triplet_kernel(target_xy_km, sat1_xy_km, sat2_xy_km, sat3_xy_km, box)
%STAGE15_COMPUTE_TRIPLET_KERNEL
% Minimal 3-satellite local geometry kernel schema.

assert(numel(target_xy_km) == 2, 'target_xy_km must be [x,y].');
assert(numel(sat1_xy_km) == 2, 'sat1_xy_km must be [x,y].');
assert(numel(sat2_xy_km) == 2, 'sat2_xy_km must be [x,y].');
assert(numel(sat3_xy_km) == 2, 'sat3_xy_km must be [x,y].');

v1 = target_xy_km(:) - sat1_xy_km(:);
v2 = target_xy_km(:) - sat2_xy_km(:);
v3 = target_xy_km(:) - sat3_xy_km(:);

rho1 = norm(v1);
rho2 = norm(v2);
rho3 = norm(v3);

u1 = v1 / max(rho1, eps);
u2 = v2 / max(rho2, eps);
u3 = v3 / max(rho3, eps);

theta12 = acosd(max(-1, min(1, dot(u1, u2))));
theta13 = acosd(max(-1, min(1, dot(u1, u3))));
theta23 = acosd(max(-1, min(1, dot(u2, u3))));

G = [u1, u2, u3] * [u1, u2, u3]';
eigsG = eig(G);
lambda_min_geom = min(eigsG);

kappa3 = struct();
kappa3.rho1_norm = rho1 / max(box.half_span_km, eps);
kappa3.rho2_norm = rho2 / max(box.half_span_km, eps);
kappa3.rho3_norm = rho3 / max(box.half_span_km, eps);
kappa3.theta12_deg = theta12;
kappa3.theta13_deg = theta13;
kappa3.theta23_deg = theta23;
kappa3.lambda_min_geom = lambda_min_geom;
end
