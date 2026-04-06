function cfg = default_ch5r_r9_params()
%DEFAULT_CH5R_R9_PARAMS
% Minimal R9 closed-loop params:
% - Koopman-DMD inner prediction
% - bubble-oriented outer scheduling
% - switch count recorded only, not optimized

cfg = default_ch5r_params(true);

cfg.ch5r.window_length_s = 60;
cfg.ch5r.window_mode = 'centered_full_only';
cfg.ch5r.window_exclude_incomplete_edges = true;

cfg.ch5r.r9 = struct();

% prediction horizon
cfg.ch5r.r9.horizon_steps = 30;

% candidate score: Psi - alpha*tau
cfg.ch5r.r9.alpha_tau = 1.0;

% local Koopman-DMD fit
cfg.ch5r.r9.dmd_recent_steps = 20;
cfg.ch5r.r9.dmd_min_points = 6;
cfg.ch5r.r9.dmd_rcond = 1e-8;

% IEKF-like measurement update
cfg.ch5r.r9.max_iekf_iters = 2;

% state model
cfg.ch5r.r9.state_dim = 6;
cfg.ch5r.r9.pos_q_km = 1e-3;
cfg.ch5r.r9.vel_q_kmps = 1e-4;

% initial estimate perturbation
cfg.ch5r.r9.init_pos_sigma_km = 5.0;
cfg.ch5r.r9.init_vel_sigma_kmps = 0.05;

% output / logging
cfg.ch5r.r9.log = struct();
cfg.ch5r.r9.log.enable = true;
cfg.ch5r.r9.log.log_every = 20;
cfg.ch5r.r9.log.show_step_timing = true;

cfg.ch5r.r9.save_outputs = true;
end
