function out = run_ch5r_phase8_4_outerA_upper_bound()
%RUN_CH5R_PHASE8_4_OUTERA_UPPER_BOUND
% Minimal outerA runner:
%   1) build mildly maneuvering truth
%   2) fit regularized DMD model
%   3) run filter prediction/update
%   4) compute NIS s_k
%   5) compute M_G(k) from dynamic window Gramian
%   6) compute P_R(k), M_R(k), and \tilde{M}_R(k)
%
% outerB is NOT connected yet.

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 80;
cfg.lambda_reg = 1e-4;
cfg.window_len = 10;
cfg.r_meas = 1e-2;
cfg.q_pos = 1e-4;
cfg.q_vel = 1e-5;
cfg.nis_alpha = 0.05;
cfg.Cr_mode = 'position';

cfg.outerA = struct();
cfg.outerA.tau_s = 1.0;
cfg.outerA.tau_g = 100.0;
cfg.outerA.tau_p = 1e-3;
cfg.outerA.alpha_s = 0.25;
cfg.outerA.alpha_g = 0.35;
cfg.outerA.alpha_p = 0.25;
cfg.outerA.eps_warn = 500.0;
cfg.outerA.Gamma_req = 5e-3;

nx = 6;
ny = 3;

% Truth: mild maneuvering
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
R = cfg.r_meas * eye(ny);
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

rng(1);
for k = 2:cfg.n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R);

    s_k = compute_nis_scalar(upd.nu, upd.S);

    % Build short predicted window from current posterior state
    x_now = upd.x_plus;
    x_seq = zeros(nx, cfg.window_len);
    F_seq = zeros(nx, nx, cfg.window_len);
    x_tmp = x_now;
    for ell = 1:cfg.window_len
        x_tmp = propagate_state_koopman_dmd(model, x_tmp);
        x_seq(:, ell) = x_tmp;
        F_seq(:,:,ell) = model.A;
    end

    W = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R);
    MG = compute_structural_metric_MG(W, Cr);

    PR_plus_k = compute_requirement_cov_PR(upd.P_plus, Cr);
    PR_minus_kp1 = compute_requirement_cov_PR(pred.P_minus, Cr);

    MR_raw = compute_raw_metric_MR(PR_plus_k, PR_minus_kp1, cfg.dt);
    outerA_core = compute_outerA_upper_bound_tildeMR(MR_raw.M_R, s_k, ny, MG.M_G, PR_plus_k, cfg.outerA);
    mode_out = classify_outerA_mode(outerA_core);
    outerA = package_outerA_result(MR_raw, MG, outerA_core, mode_out, PR_plus_k);

    idx = k - 1;
    trace_data.nis(idx) = s_k;
    trace_data.MR(idx) = outerA.M_R;
    trace_data.MG(idx) = outerA.M_G;
    trace_data.tildeMR(idx) = outerA.tildeMR;
    trace_data.GammaA(idx) = outerA.GammaA;
    trace_data.mode_code(idx) = outerA.mode_code;
    trace_data.mode_label(idx) = string(outerA.mode);
    trace_data.lambda_max_PR(idx) = outerA.lambda_max_PR;

    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

k_idx = (1:n_eval).';

summary = struct();
summary.n_steps = cfg.n_steps;
summary.mean_nis = mean(trace_data.nis);
summary.mean_MR = mean(trace_data.MR);
summary.mean_MG = mean(trace_data.MG);
summary.mean_tildeMR = mean(trace_data.tildeMR);
summary.mean_GammaA = mean(trace_data.GammaA);
summary.safe_ratio = mean(trace_data.mode_code == 1);
summary.warn_ratio = mean(trace_data.mode_code == 2);
summary.repair_ratio = mean(trace_data.mode_code == 3);
summary.emergency_ratio = mean(trace_data.mode_code == 4);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_4_outerA_upper_bound');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_4_outerA_upper_bound_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_4_outerA_upper_bound_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_MR_vs_tildeMR_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_outerA_mode_timeline_' stamp '.png']);

fig1 = plot_MR_vs_tildeMR(k_idx, trace_data.MR, trace_data.tildeMR, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_outerA_mode_timeline(k_idx, trace_data.mode_code, 'off');
saveas(fig2, fig2_file);
close(fig2);

save(mat_file, 'cfg', 'model', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.4] outerA upper-bound summary ===')
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
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'fig1_file', fig1_file, ...
    'fig2_file', fig2_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, mat_file, fig1_file, fig2_file)
lines = {};
lines{end+1} = '# Phase R8.4 outerA Upper-Bound';
lines{end+1} = '';
lines{end+1} = '## Summary';
lines{end+1} = '';
lines{end+1} = ['- n_steps = ', num2str(summary.n_steps)];
lines{end+1} = ['- mean_nis = ', num2str(summary.mean_nis, '%.12g')];
lines{end+1} = ['- mean_MR = ', num2str(summary.mean_MR, '%.12g')];
lines{end+1} = ['- mean_MG = ', num2str(summary.mean_MG, '%.12g')];
lines{end+1} = ['- mean_tildeMR = ', num2str(summary.mean_tildeMR, '%.12g')];
lines{end+1} = ['- mean_GammaA = ', num2str(summary.mean_GammaA, '%.12g')];
lines{end+1} = ['- safe_ratio = ', num2str(summary.safe_ratio, '%.12g')];
lines{end+1} = ['- warn_ratio = ', num2str(summary.warn_ratio, '%.12g')];
lines{end+1} = ['- repair_ratio = ', num2str(summary.repair_ratio, '%.12g')];
lines{end+1} = ['- emergency_ratio = ', num2str(summary.emergency_ratio, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## Artifacts';
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
md = strjoin(lines, newline);
end
