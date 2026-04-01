function kappa2 = stage15_compute_pair_kernel_3d(target_state, sat1_state, sat2_state, box)
%STAGE15_COMPUTE_PAIR_KERNEL_3D
% Minimal 3D 2-sensor local geometry kernel.
%
% target_state = [x,y,z,vx,vy,vz]
% sat*_state   = [x,y,z,vx,vy,vz]

assert(numel(target_state) == 6, 'target_state must be 6D.');
assert(numel(sat1_state) == 6, 'sat1_state must be 6D.');
assert(numel(sat2_state) == 6, 'sat2_state must be 6D.');

pt = target_state(1:3).';
p1 = sat1_state(1:3).';
p2 = sat2_state(1:3).';

v1 = pt - p1;
v2 = pt - p2;

rho1 = norm(v1);
rho2 = norm(v2);

u1 = v1 / max(rho1, eps);
u2 = v2 / max(rho2, eps);

cosang = max(-1, min(1, dot(u1, u2)));
crossing_angle_deg = acosd(cosang);

G = [u1(:), u2(:)] * [u1(:), u2(:)]';
eigsG = eig(G);
lambda_min_geom = min(eigsG);

delta_h1 = target_state(3) - sat1_state(3);
delta_h2 = target_state(3) - sat2_state(3);

kappa2 = struct();
kappa2.rho1_norm = rho1 / max(box.half_span_km, eps);
kappa2.rho2_norm = rho2 / max(box.half_span_km, eps);
kappa2.delta_h1_norm = delta_h1 / max(box.height_ref_km, eps);
kappa2.delta_h2_norm = delta_h2 / max(box.height_ref_km, eps);
kappa2.crossing_angle_deg = crossing_angle_deg;
kappa2.lambda_min_geom = lambda_min_geom;
end
