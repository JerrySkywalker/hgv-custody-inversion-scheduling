function out = run_ch5r_phase8_A_bubble_variable_smoke()
%RUN_CH5R_PHASE8_A_BUBBLE_VARIABLE_SMOKE
% R8-A (redone):
%   requirement-induced bubble main variable
%
%   Xi_B(k,H) = min_{ell=1,...,H} [Gamma_req - lambda_max(P_r,k+ell|k^+)]
%   R_B       = max(0, -Xi_B)
%
% No artificial hyper-parameters such as rho_r / eps_B are used.

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

    MG_forecast = zeros(cfg.window_len, 1);

    for ell = 1:cfg.window_len
        x_tmp = propagate_state_koopman_dmd(model, x_tmp);
        x_seq(:, ell) = x_tmp;
        F_seq(:,:,ell) = model.A;

        % one-step covariance prediction + hypothetical update with same nominal H/R
        P_minus_ell = model.A * P_tmp * model.A.' + Q;
        H_ell = H_fun(x_tmp);
        S_ell = H_ell * P_minus_ell * H_ell.' + R_single;
        K_ell = (P_minus_ell * H_ell.') / S_ell;
        I = eye(nx);
        P_plus_ell = (I - K_ell * H_ell) * P_minus_ell * (I - K_ell * H_ell).' + K_ell * R_single * K_ell.';
        P_plus_ell = 0.5 * (P_plus_ell + P_plus_ell.');

        Pplus_seq(:,:,ell) = P_plus_ell;
        P_tmp = P_plus_ell;

        W_ell = compute_predicted_window_gramian(F_seq(:,:,1:ell), x_seq(:,1:ell), H_fun, R_single);
        MG_ell = compute_structural_metric_MG(W_ell, Cr);
        MG_forecast(ell) = MG_ell.M_G;
    end

    W_cur = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R_single);
    MG_cur = compute_structural_metric_MG(W_cur, Cr);

    req = compute_requirement_margin_series_forecast(Pplus_seq, Cr, cfg.requirement.Gamma_req);
    bubble = compute_requirement_induced_bubble_margin(req.margin_series);
    bubble_pack = package_requirement_bubble_result(MG_cur, req, bubble);

    idx = k - 1;
    trace_data.MG(idx) = bubble_pack.M_G;
    trace_data.Xi_B(idx) = bubble_pack.Xi_B;
    trace_data.R_B(idx) = bubble_pack.R_B;
    trace_data.is_bubble(idx) = bubble_pack.is_bubble;
    trace_data.idx_min(idx) = bubble_pack.idx_min;
    trace_data.min_margin(idx) = min(bubble_pack.margin_series);
    trace_data.mean_margin(idx) = mean(bubble_pack.margin_series);
    trace_data.min_lambda_max_PR(idx) = min(bubble_pack.lambda_max_PR_series);
    trace_data.max_lambda_max_PR(idx) = max(bubble_pack.lambda_max_PR_series);

    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

summary = struct();
summary.n_steps = cfg.n_steps;
summary.mean_MG = mean(trace_data.MG);
summary.mean_Xi_B = mean(trace_data.Xi_B);
summary.mean_R_B = mean(trace_data.R_B);
summary.mean_min_margin = mean(trace_data.min_margin);
summary.mean_mean_margin = mean(trace_data.mean_margin);
summary.mean_min_lambda_max_PR = mean(trace_data.min_lambda_max_PR);
summary.mean_max_lambda_max_PR = mean(trace_data.max_lambda_max_PR);
summary.bubble_steps = sum(trace_data.is_bubble);
summary.bubble_fraction = mean(trace_data.is_bubble);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_A_bubble_variable_smoke');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_A_bubble_variable_smoke_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_A_bubble_variable_smoke_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_phaseR8_A_requirement_XiB_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phaseR8_A_bubble_state_' stamp '.png']);

k_idx = (1:n_eval).';
fig1 = plot_requirement_margin_forecast(k_idx, trace_data.Xi_B, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_bubble_state_timeline(k_idx, trace_data.is_bubble, 'off');
saveas(fig2, fig2_file);
close(fig2);

save(mat_file, 'cfg', 'model', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8-A-redo] requirement-induced bubble variable smoke summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])

out = struct();
out.cfg = cfg;
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
lines{end+1} = '# Phase R8-A-redo requirement-induced bubble variable smoke';
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
