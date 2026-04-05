function out = run_ch5r_phase8_B_outerA_bubble_prediction()
%RUN_CH5R_PHASE8_B_OUTERA_BUBBLE_PREDICTION
% R8-B:
%   outerA is re-centered as a bubble prediction ring.
%
% Direct outerA outputs:
%   Xi_B, R_B, tau_B, A_B
%
% Bubble main variable is requirement-induced:
%   Xi_B = min_{ell<=H} [Gamma_req - lambda_max(P_r,k+ell|k^+)]

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 80;
cfg.lambda_reg = 1e-4;
cfg.window_len = 8;
cfg.r_meas = 1.0e-2;
cfg.q_pos = 1.0e-4;
cfg.q_vel = 1.0e-5;
cfg.Cr_mode = 'position';

cfg.requirement = struct();
cfg.requirement.Gamma_req = 1.0e-2;

nx = 6;
ny = 3;

x_truth = zeros(cfg.n_steps, nx);
x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
for k = 2:cfg.n_steps
    ax = 0.02 * sin(0.09 * (k-1));
    ay = 0.016 * cos(0.06 * (k-1));
    az = 0.012 * sin(0.05 * (k-1));

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

h_fun = @(x) x(1:3);
H_fun = @(x) [eye(3), zeros(3,3)];
Cr = build_requirement_projection_Cr(nx, cfg.Cr_mode);

x0_est = x_truth(1,:).' + [0.05; -0.04; 0.03; 0.01; -0.01; 0.02];
P0 = diag([1e-2 1e-2 1e-2 1e-3 1e-3 1e-3]);
fs = package_filter_state(x0_est, P0);

n_eval = cfg.n_steps - 1;
trace_data = struct();
trace_data.MG = zeros(n_eval, 1);
trace_data.Xi_B = zeros(n_eval, 1);
trace_data.R_B = zeros(n_eval, 1);
trace_data.is_bubble = false(n_eval, 1);
trace_data.idx_min = zeros(n_eval, 1);
trace_data.tau_B_idx = inf(n_eval, 1);
trace_data.tau_B_time_s = inf(n_eval, 1);
trace_data.A_B = zeros(n_eval, 1);
trace_data.min_margin = zeros(n_eval, 1);
trace_data.mean_margin = zeros(n_eval, 1);
trace_data.min_lambda_max_PR = zeros(n_eval, 1);
trace_data.max_lambda_max_PR = zeros(n_eval, 1);

rng(1);
for k = 2:cfg.n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R_single, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R_single);

    x_now = upd.x_plus;
    x_seq = zeros(nx, cfg.window_len);
    F_seq = zeros(nx, nx, cfg.window_len);
    Pplus_seq = zeros(nx, nx, cfg.window_len);

    x_tmp = x_now;
    P_tmp = upd.P_plus;

    for ell = 1:cfg.window_len
        x_tmp = propagate_state_koopman_dmd(model, x_tmp);
        x_seq(:, ell) = x_tmp;
        F_seq(:,:,ell) = model.A;

        P_minus_ell = model.A * P_tmp * model.A.' + Q;
        H_ell = H_fun(x_tmp);
        S_ell = H_ell * P_minus_ell * H_ell.' + R_single;
        K_ell = (P_minus_ell * H_ell.') / S_ell;
        I = eye(nx);
        P_plus_ell = (I - K_ell * H_ell) * P_minus_ell * (I - K_ell * H_ell).' + K_ell * R_single * K_ell.';
        P_plus_ell = 0.5 * (P_plus_ell + P_plus_ell.');

        Pplus_seq(:,:,ell) = P_plus_ell;
        P_tmp = P_plus_ell;
    end

    W_cur = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R_single);
    MG_cur = compute_structural_metric_MG(W_cur, Cr);

    req = compute_requirement_margin_series_forecast(Pplus_seq, Cr, cfg.requirement.Gamma_req);
    bubble = compute_requirement_induced_bubble_margin(req.margin_series);
    tau = compute_requirement_induced_failure_time_tauB(req.margin_series, cfg.dt);
    area = compute_requirement_induced_bubble_area_AB(req.lambda_max_PR_series, cfg.requirement.Gamma_req, cfg.dt);

    pred_pack = package_outerA_bubble_prediction_result(MG_cur, req, bubble, tau, area);

    idx = k - 1;
    trace_data.MG(idx) = pred_pack.M_G;
    trace_data.Xi_B(idx) = pred_pack.Xi_B;
    trace_data.R_B(idx) = pred_pack.R_B;
    trace_data.is_bubble(idx) = pred_pack.is_bubble;
    trace_data.idx_min(idx) = pred_pack.idx_min;
    trace_data.tau_B_idx(idx) = pred_pack.tau_B_idx;
    trace_data.tau_B_time_s(idx) = pred_pack.tau_B_time_s;
    trace_data.A_B(idx) = pred_pack.A_B;
    trace_data.min_margin(idx) = min(pred_pack.margin_series);
    trace_data.mean_margin(idx) = mean(pred_pack.margin_series);
    trace_data.min_lambda_max_PR(idx) = min(pred_pack.lambda_max_PR_series);
    trace_data.max_lambda_max_PR(idx) = max(pred_pack.lambda_max_PR_series);

    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

summary = struct();
summary.n_steps = cfg.n_steps;
summary.mean_MG = mean(trace_data.MG);
summary.mean_Xi_B = mean(trace_data.Xi_B);
summary.mean_R_B = mean(trace_data.R_B);
summary.mean_tau_B_time_s = mean(trace_data.tau_B_time_s(isfinite(trace_data.tau_B_time_s)));
summary.has_failure_fraction = mean(isfinite(trace_data.tau_B_time_s));
summary.mean_A_B = mean(trace_data.A_B);
summary.mean_min_margin = mean(trace_data.min_margin);
summary.mean_mean_margin = mean(trace_data.mean_margin);
summary.mean_min_lambda_max_PR = mean(trace_data.min_lambda_max_PR);
summary.mean_max_lambda_max_PR = mean(trace_data.max_lambda_max_PR);
summary.bubble_steps = sum(trace_data.is_bubble);
summary.bubble_fraction = mean(trace_data.is_bubble);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_B_outerA_bubble_prediction');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_B_outerA_bubble_prediction_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_B_outerA_bubble_prediction_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_phaseR8_B_XiB_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phaseR8_B_tauB_' stamp '.png']);
fig3_file = fullfile(out_dir, ['plot_phaseR8_B_AB_' stamp '.png']);

k_idx = (1:n_eval).';
fig1 = plot_requirement_margin_forecast(k_idx, trace_data.Xi_B, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_tauB_timeline(k_idx, trace_data.tau_B_time_s, 'off');
saveas(fig2, fig2_file);
close(fig2);

fig3 = plot_AB_timeline(k_idx, trace_data.A_B, 'off');
saveas(fig3, fig3_file);
close(fig3);

save(mat_file, 'cfg', 'model', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file, fig3_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8-B] outerA bubble prediction summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])
disp(['fig3 file            : ' fig3_file])

out = struct();
out.cfg = cfg;
out.trace_data = trace_data;
out.summary = summary;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'fig1_file', fig1_file, ...
    'fig2_file', fig2_file, ...
    'fig3_file', fig3_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, mat_file, fig1_file, fig2_file, fig3_file)
lines = {};
lines{end+1} = '# Phase R8-B outerA bubble prediction';
lines{end+1} = '';
fns = fieldnames(summary);
for i = 1:numel(fns)
    v = summary.(fns{i});
    if isnumeric(v) && isscalar(v)
        if isfinite(v)
            lines{end+1} = ['- ', fns{i}, ' = ', num2str(v, '%.12g')];
        else
            lines{end+1} = ['- ', fns{i}, ' = inf'];
        end
    end
end
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
lines{end+1} = ['- fig3 file: `', fig3_file, '`'];
md = strjoin(lines, newline);
end
