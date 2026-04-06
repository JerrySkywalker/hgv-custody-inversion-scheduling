function [x_pred, P_pred] = propagate_koopman_state(x, P, model, cfg)
%PROPAGATE_KOOPMAN_STATE
% One-step propagation using local affine DMD model.

A = model.A;
b = model.b;

if isfield(model, 'Q') && ~isempty(model.Q)
    Q = model.Q;
else
    nx = numel(x);
    Q = zeros(nx);
    if nx >= 6
        qpos = cfg.ch5r.r9.pos_q_km^2;
        qvel = cfg.ch5r.r9.vel_q_kmps^2;
        Q(1:3,1:3) = qpos * eye(3);
        Q(4:6,4:6) = qvel * eye(3);
    else
        Q = 1e-6 * eye(nx);
    end
end

x_pred = A * x + b;
P_pred = A * P * A' + Q;
P_pred = 0.5 * (P_pred + P_pred');
end
