function out = run_ch5r_phase8_5_outerB_continuous()
%RUN_CH5R_PHASE8_5_OUTERB_CONTINUOUS
% Phase R8.6b-1 high-pressure version:
%   same normalized outerB scoring
%   but stronger scenario pressure for compare separability

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 80;
cfg.lambda_reg = 1e-4;
cfg.window_len = 8;
cfg.r_meas = 1.5e-2;
cfg.q_pos = 2e-4;
cfg.q_vel = 3e-5;
cfg.Cr_mode = 'position';
cfg.nis_alpha = 0.05;

cfg.outerA = struct();
cfg.outerA.tau_s = 1.0;
cfg.outerA.tau_g = 120.0;
cfg.outerA.tau_p = 8e-4;
cfg.outerA.alpha_s = 0.25;
cfg.outerA.alpha_g = 0.45;
cfg.outerA.alpha_p = 0.35;
cfg.outerA.eps_warn = 900.0;
cfg.outerA.Gamma_req = 3e-3;

cfg.outerB = struct();
cfg.outerB.alpha0 = 1.0;
cfg.outerB.beta0 = 1.0;
cfg.outerB.eta0 = 2.0;
cfg.outerB.mu0 = 0.5;
cfg.outerB.kappa_alpha = 220.0;
cfg.outerB.kappa_beta = 120.0;
cfg.outerB.kappa_eta = 80.0;

cfg.score = struct();
cfg.score.switch_cost = 0.25;
cfg.score.resource_cost = 2.0;
cfg.score.tie_break_gap = 0.05;

nx = 6;
ny = 3;
Ns = 4;

sat_pos = [ ...
    -6000,  6000, -6000,  6000; ...
    -6000, -6000,  6000,  6000; ...
     5000,  5000,  5000,  5000];

pair_bank = nchoosek(1:Ns, 2);

x_truth = zeros(cfg.n_steps, nx);
x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
for k = 2:cfg.n_steps
    ax = 0.03 * sin(0.11 * (k-1));
    ay = 0.024 * cos(0.07 * (k-1));
    az = 0.018 * sin(0.06 * (k-1));

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

trace_data.alpha_k = zeros(n_eval, 1);
trace_data.beta_k = zeros(n_eval, 1);
trace_data.eta_k = zeros(n_eval, 1);
trace_data.mu_k = zeros(n_eval, 1);
trace_data.selected_pair = zeros(n_eval, 2);
trace_data.selected_score = zeros(n_eval, 1);
trace_data.selected_MG_pair = zeros(n_eval, 1);
trace_data.selected_lambda_max_PR_plus = zeros(n_eval, 1);
trace_data.switch_cost = zeros(n_eval, 1);
trace_data.gap12 = zeros(n_eval, 1);

trace_data.norm_MG = zeros(n_eval, 1);
trace_data.norm_PR = zeros(n_eval, 1);
trace_data.norm_SC = zeros(n_eval, 1);
trace_data.norm_RC = zeros(n_eval, 1);

trace_data.xtruth_series = x_truth(2:end, :);
trace_data.xhat_plus_series = zeros(n_eval, nx);
trace_data.Pplus_series = zeros(nx, nx, n_eval);

prev_pair = [];

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

    weights = map_tildeMR_to_scheduler_weights(outerA.tildeMR, cfg.outerB);

    sel = select_pair_dualloop_continuous(pred, pair_bank, sat_pos, x_seq, F_seq, Cr, R_pair, ...
        weights, prev_pair, cfg.score);

    outerB = package_outerB_result(k-1, sel.best_pair, weights, sel.best_eval);

    idx = k - 1;
    trace_data.nis(idx) = s_k;
    trace_data.MR(idx) = outerA.M_R;
    trace_data.MG(idx) = outerA.M_G;
    trace_data.tildeMR(idx) = outerA.tildeMR;
    trace_data.GammaA(idx) = outerA.GammaA;
    trace_data.mode_code(idx) = outerA.mode_code;
    trace_data.mode_label(idx) = string(outerA.mode);
    trace_data.lambda_max_PR(idx) = outerA.lambda_max_PR;

    trace_data.alpha_k(idx) = outerB.alpha_k;
    trace_data.beta_k(idx) = outerB.beta_k;
    trace_data.eta_k(idx) = outerB.eta_k;
    trace_data.mu_k(idx) = outerB.mu_k;
    trace_data.selected_pair(idx,:) = outerB.pair;
    trace_data.selected_score(idx) = outerB.score;
    trace_data.selected_MG_pair(idx) = outerB.M_G_pair;
    trace_data.selected_lambda_max_PR_plus(idx) = outerB.lambda_max_PR_plus;
    trace_data.switch_cost(idx) = outerB.switch_cost;
    trace_data.gap12(idx) = sel.gap12;

    trace_data.norm_MG(idx) = outerB.norm_MG;
    trace_data.norm_PR(idx) = outerB.norm_PR;
    trace_data.norm_SC(idx) = outerB.norm_SC;
    trace_data.norm_RC(idx) = outerB.norm_RC;

    trace_data.xhat_plus_series(idx,:) = upd.x_plus.';
    trace_data.Pplus_series(:,:,idx) = upd.P_plus;

    prev_pair = outerB.pair;
    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

k_idx = (1:n_eval).';
switch_count = sum(trace_data.switch_cost > 0);

summary = struct();
summary.n_steps = cfg.n_steps;
summary.mean_nis = mean(trace_data.nis);
summary.mean_MR = mean(trace_data.MR);
summary.mean_MG = mean(trace_data.MG);
summary.mean_tildeMR = mean(trace_data.tildeMR);
summary.mean_GammaA = mean(trace_data.GammaA);
summary.mean_alpha_k = mean(trace_data.alpha_k);
summary.mean_beta_k = mean(trace_data.beta_k);
summary.mean_eta_k = mean(trace_data.eta_k);
summary.mean_selected_score = mean(trace_data.selected_score);
summary.mean_selected_MG_pair = mean(trace_data.selected_MG_pair);
summary.mean_selected_lambda_max_PR_plus = mean(trace_data.selected_lambda_max_PR_plus);
summary.mean_gap12 = mean(trace_data.gap12);
summary.mean_norm_MG = mean(trace_data.norm_MG);
summary.mean_norm_PR = mean(trace_data.norm_PR);
summary.mean_norm_SC = mean(trace_data.norm_SC);
summary.mean_norm_RC = mean(trace_data.norm_RC);
summary.switch_count = switch_count;
summary.safe_ratio = mean(trace_data.mode_code == 1);
summary.warn_ratio = mean(trace_data.mode_code == 2);
summary.repair_ratio = mean(trace_data.mode_code == 3);
summary.emergency_ratio = mean(trace_data.mode_code == 4);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5_outerB_continuous');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_5_outerB_continuous_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_5_outerB_continuous_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_outerB_pair_timeline_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_tildeMR_vs_weights_' stamp '.png']);

fig1 = plot_outerB_pair_timeline(k_idx, trace_data.selected_pair, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_tildeMR_vs_weight_timeline(k_idx, trace_data.tildeMR, trace_data.alpha_k, ...
    trace_data.beta_k, trace_data.eta_k, 'off');
saveas(fig2, fig2_file);
close(fig2);

save(mat_file, 'cfg', 'model', 'sat_pos', 'pair_bank', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.6b-base] high-pressure outerB summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])

out = struct();
out.cfg = cfg;
out.model = model;
out.trace_data = trace_data;
out.summary = summary;
out.paths = struct('mat_file', mat_file, 'md_file', md_file, 'fig1_file', fig1_file, 'fig2_file', fig2_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, mat_file, fig1_file, fig2_file)
lines = {};
lines{end+1} = '# Phase R8.6b-base high-pressure outerB';
lines{end+1} = '';
fns = fieldnames(summary);
for i = 1:numel(fns)
    v = summary.(fns{i});
    if isnumeric(v) && isscalar(v)
        lines{end+1} = ['- ', fns{i}, ' = ', num2str(v, '%.12g')];
    end
end
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
md = strjoin(lines, newline);
end
