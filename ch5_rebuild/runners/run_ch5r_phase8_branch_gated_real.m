function out = run_ch5r_phase8_branch_gated_real()
%RUN_CH5R_PHASE8_BRANCH_GATED_REAL
% Real gated-shell branch for R8.6-real compare.
%
% Gate rule:
%   update pair only if outerA mode_code >= 3
%   otherwise hold previous pair

closed = run_ch5r_phase8_5_outerB_continuous();
pair_seed = closed.trace_data.selected_pair(1,:);

cfg = closed.cfg;
nx = 6;
ny = 3;
Ns = 6;

sat_pos = [ ...
    -8000,  8000, -8000,  8000,     0,     0; ...
    -8000, -8000,  8000,  8000,     0,     0; ...
     6000,  6000,  6000,  6000,  9000, -9000];
pair_bank = nchoosek(1:Ns, 2);

x_truth = zeros(cfg.n_steps, nx);
x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
for k = 2:cfg.n_steps
    ax = 0.01 * sin(0.08 * (k-1));
    ay = 0.008 * cos(0.05 * (k-1));
    az = 0.006 * sin(0.04 * (k-1));

    x_truth(k,4) = x_truth(k-1,4) + cfg.dt * ax;
    x_truth(k,5) = x_truth(k-1,5) + cfg.dt * ay;
    x_truth(k,6) = x_truth(k-1,6) + cfg.dt * az;

    x_truth(k,1:3) = x_truth(k-1,1:3) + cfg.dt * x_truth(k,4:6);
end

X_prev = x_truth(1:end-1,:).';
X_next = x_truth(2:end,:).';
model = fit_local_dmd_operator_reg(X_prev, X_next, 'lambda_reg', cfg.lambda_reg);

Q = diag([cfg.q_pos cfg.q_pos cfg.q_pos cfg.q_vel cfg.q_vel cfg.q_vel]);
R_single = cfg.r_meas * eye(ny);
R_pair = blkdiag(R_single, R_single);

h_fun = @(x) x(1:3);
H_fun = @(x) [eye(3), zeros(3,3)];
Cr = build_requirement_projection_Cr(nx, cfg.Cr_mode);

x0_est = x_truth(1,:).' + [0.05; -0.04; 0.03; 0.01; -0.01; 0.02];
P0 = diag([1e-2 1e-2 1e-2 1e-3 1e-3 1e-3]);
fs = package_filter_state(x0_est, P0);

n_eval = cfg.n_steps - 1;
trace_data = struct();
trace_data.nis = zeros(n_eval, 1);
trace_data.MR = zeros(n_eval, 1);
trace_data.MG = zeros(n_eval, 1);
trace_data.tildeMR = zeros(n_eval, 1);
trace_data.GammaA = zeros(n_eval, 1);
trace_data.mode_code = zeros(n_eval, 1);
trace_data.mode_label = strings(n_eval, 1);
trace_data.lambda_max_PR = zeros(n_eval, 1);
trace_data.selected_pair = zeros(n_eval, 2);
trace_data.switch_cost = zeros(n_eval, 1);
trace_data.xtruth_series = x_truth(2:end, :);
trace_data.xhat_plus_series = zeros(n_eval, nx);
trace_data.Pplus_series = zeros(nx, nx, n_eval);

prev_pair = pair_seed;

rng(1);
for k = 2:cfg.n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R_single, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R_single);

    s_k = compute_nis_scalar(upd.nu, upd.S);

    x_now = upd.x_plus;
    x_seq = zeros(nx, cfg.window_len);
    F_seq = zeros(nx, nx, cfg.window_len);
    x_tmp = x_now;
    for ell = 1:cfg.window_len
        x_tmp = propagate_state_koopman_dmd(model, x_tmp);
        x_seq(:, ell) = x_tmp;
        F_seq(:,:,ell) = model.A;
    end

    W = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R_single);
    MG = compute_structural_metric_MG(W, Cr);

    PR_plus_k = compute_requirement_cov_PR(upd.P_plus, Cr);
    PR_minus_kp1 = compute_requirement_cov_PR(pred.P_minus, Cr);

    MR_raw = compute_raw_metric_MR(PR_plus_k, PR_minus_kp1, cfg.dt);
    outerA_core = compute_outerA_upper_bound_tildeMR(MR_raw.M_R, s_k, ny, MG.M_G, PR_plus_k, cfg.outerA);
    mode_out = classify_outerA_mode(outerA_core);
    outerA = package_outerA_result(MR_raw, MG, outerA_core, mode_out, PR_plus_k);

    if outerA.mode_code >= 3
        weights = map_tildeMR_to_scheduler_weights(outerA.tildeMR, cfg.outerB);
        sel = select_pair_dualloop_continuous(pred, pair_bank, sat_pos, x_seq, F_seq, Cr, R_pair, ...
            weights, prev_pair, cfg.score);
        pair_now = sel.best_pair;
    else
        pair_now = prev_pair;
    end

    idx = k - 1;
    trace_data.nis(idx) = s_k;
    trace_data.MR(idx) = outerA.M_R;
    trace_data.MG(idx) = outerA.M_G;
    trace_data.tildeMR(idx) = outerA.tildeMR;
    trace_data.GammaA(idx) = outerA.GammaA;
    trace_data.mode_code(idx) = outerA.mode_code;
    trace_data.mode_label(idx) = string(outerA.mode);
    trace_data.lambda_max_PR(idx) = outerA.lambda_max_PR;
    trace_data.selected_pair(idx,:) = pair_now;
    trace_data.switch_cost(idx) = double(any(sort(pair_now) ~= sort(prev_pair)));
    trace_data.xhat_plus_series(idx,:) = upd.x_plus.';
    trace_data.Pplus_series(:,:,idx) = upd.P_plus;

    prev_pair = pair_now;
    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

summary = struct();
summary.switch_count = sum(trace_data.switch_cost > 0);

out = struct();
out.name = 'R7-like_gated_real';
out.cfg = cfg;
out.trace_data = trace_data;
out.summary = summary;
out.paths = struct();
end
