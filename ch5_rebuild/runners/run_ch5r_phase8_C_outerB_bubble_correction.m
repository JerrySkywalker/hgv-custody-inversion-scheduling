function out = run_ch5r_phase8_C_outerB_bubble_correction()
%RUN_CH5R_PHASE8_C_OUTERB_BUBBLE_CORRECTION
% R8-C:
%   outerB is re-centered as a bubble correction ring.
%
% Selection rule:
%   1) maximize Xi_B
%   2) maximize tau_B
%   3) minimize A_B
%   4) minimize switch cost
%   5) minimize resource cost

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
Ns = 6;

sat_pos = [ ...
    -8000,  8000, -8000,  8000,     0,     0; ...
    -8000, -8000,  8000,  8000,     0,     0; ...
     6000,  6000,  6000,  6000,  9000, -9000];

pair_bank = nchoosek(1:Ns, 2);

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
trace_data.selected_pair = zeros(n_eval, 2);
trace_data.Xi_B = zeros(n_eval, 1);
trace_data.R_B = zeros(n_eval, 1);
trace_data.tau_B_time_s = inf(n_eval, 1);
trace_data.A_B = zeros(n_eval, 1);
trace_data.is_bubble = false(n_eval, 1);
trace_data.switch_cost = zeros(n_eval, 1);
trace_data.M_G = zeros(n_eval, 1);

prev_pair = [];

rng(1);
for k = 2:cfg.n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R_single, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R_single);

    sel = select_pair_bubble_correction( ...
        upd.x_plus, upd.P_plus, pair_bank, sat_pos, model, Q, H_fun, R_single, Cr, ...
        cfg.requirement.Gamma_req, cfg.dt, cfg.window_len, prev_pair);

    idx = k - 1;
    trace_data.selected_pair(idx,:) = sel.best_pair;
    trace_data.Xi_B(idx) = sel.best_eval.Xi_B;
    trace_data.R_B(idx) = sel.best_eval.R_B;
    trace_data.tau_B_time_s(idx) = sel.best_eval.tau_B_time_s;
    trace_data.A_B(idx) = sel.best_eval.A_B;
    trace_data.is_bubble(idx) = sel.best_eval.is_bubble;
    trace_data.switch_cost(idx) = sel.best_eval.switch_cost;
    trace_data.M_G(idx) = sel.best_eval.M_G;

    prev_pair = sel.best_pair;
    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

summary = struct();
summary.n_steps = cfg.n_steps;
summary.mean_Xi_B = mean(trace_data.Xi_B);
summary.mean_R_B = mean(trace_data.R_B);
summary.mean_tau_B_time_s = mean(trace_data.tau_B_time_s(isfinite(trace_data.tau_B_time_s)));
summary.has_failure_fraction = mean(isfinite(trace_data.tau_B_time_s));
summary.mean_A_B = mean(trace_data.A_B);
summary.bubble_steps = sum(trace_data.is_bubble);
summary.bubble_fraction = mean(trace_data.is_bubble);
summary.switch_count = sum(trace_data.switch_cost > 0);
summary.mean_M_G = mean(trace_data.M_G);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_C_outerB_bubble_correction');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_C_outerB_bubble_correction_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_C_outerB_bubble_correction_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_phaseR8_C_XiB_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phaseR8_C_tauB_' stamp '.png']);
fig3_file = fullfile(out_dir, ['plot_phaseR8_C_pairs_' stamp '.png']);

k_idx = (1:n_eval).';
fig1 = plot_requirement_margin_forecast(k_idx, trace_data.Xi_B, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_tauB_timeline(k_idx, trace_data.tau_B_time_s, 'off');
saveas(fig2, fig2_file);
close(fig2);

fig3 = plot_pair_selection_timeline(k_idx, trace_data.selected_pair, 'off');
saveas(fig3, fig3_file);
close(fig3);

save(mat_file, 'cfg', 'model', 'sat_pos', 'pair_bank', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file, fig3_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8-C] outerB bubble correction summary ===')
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
lines{end+1} = '# Phase R8-C outerB bubble correction';
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
