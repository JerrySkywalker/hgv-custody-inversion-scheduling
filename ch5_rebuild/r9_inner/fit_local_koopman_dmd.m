function model = fit_local_koopman_dmd(X_hist, dt, cfg)
%FIT_LOCAL_KOOPMAN_DMD
% Minimal affine DMD / Koopman-like local propagator:
%   x_{k+1} ~ A x_k + b

[nx, npts] = size(X_hist);

if npts < max(cfg.ch5r.r9.dmd_min_points, 3)
    model = local_fallback_model(nx, dt, cfg);
    model.fit_mode = 'fallback_insufficient_points';
    return;
end

X0 = X_hist(:,1:end-1);
X1 = X_hist(:,2:end);

Z = [X0; ones(1,size(X0,2))];
if rcond(Z*Z.') < cfg.ch5r.r9.dmd_rcond
    model = local_fallback_model(nx, dt, cfg);
    model.fit_mode = 'fallback_rank_deficient';
    return;
end

M = X1 / Z;
A = M(:,1:nx);
b = M(:,end);

model = struct();
model.A = A;
model.b = b;
model.fit_mode = 'affine_dmd';
end

function model = local_fallback_model(nx, dt, cfg)
A = eye(nx);
if nx >= 6
    A(1,4) = dt;
    A(2,5) = dt;
    A(3,6) = dt;
end
b = zeros(nx,1);

Q = zeros(nx);
if nx >= 6
    qpos = cfg.ch5r.r9.pos_q_km^2;
    qvel = cfg.ch5r.r9.vel_q_kmps^2;
    Q(1:3,1:3) = qpos * eye(3);
    Q(4:6,4:6) = qvel * eye(3);
else
    Q = 1e-6 * eye(nx);
end

model = struct();
model.A = A;
model.b = b;
model.Q = Q;
end
