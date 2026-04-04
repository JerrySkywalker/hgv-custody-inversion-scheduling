function out = run_ch5r_phase8_1_filter_smoke()
%RUN_CH5R_PHASE8_1_FILTER_SMOKE
% Minimal smoke for Phase R8.1 inner-loop filter foundation.
%
% This runner:
%   1) builds a simple synthetic trajectory segment
%   2) fits a local DMD operator
%   3) runs predict/update EKF steps
%   4) outputs residual/covariance sanity checks
%
% Note:
%   This is intentionally minimal and does NOT yet connect outerA/outerB.

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 40;
cfg.lambda_reg = 1e-6;
cfg.q_pos = 1e-4;
cfg.q_vel = 1e-5;
cfg.r_meas = 1e-2;

nx = 6;
ny = 3;

% Synthetic truth: constant velocity motion
t = (0:cfg.n_steps-1).' * cfg.dt;
x_truth = zeros(cfg.n_steps, nx);
x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
for k = 2:cfg.n_steps
    x_truth(k,1:3) = x_truth(k-1,1:3) + cfg.dt * x_truth(k-1,4:6);
    x_truth(k,4:6) = x_truth(k-1,4:6);
end

% Fit local DMD from truth samples
X_prev = x_truth(1:end-1,:).';
X_next = x_truth(2:end,:).';
model = fit_local_dmd_operator(X_prev, X_next, 'lambda_reg', cfg.lambda_reg);

Q = diag([cfg.q_pos cfg.q_pos cfg.q_pos cfg.q_vel cfg.q_vel cfg.q_vel]);
R = cfg.r_meas * eye(ny);

h_fun = @(x) x(1:3);
H_fun = @(x) [eye(3), zeros(3,3)];

x0_est = x_truth(1,:).' + [0.05; -0.04; 0.03; 0.01; -0.01; 0.02];
P0 = diag([1e-2 1e-2 1e-2 1e-3 1e-3 1e-3]);
fs = package_filter_state(x0_est, P0);

trace_data = struct();
trace_data.x_minus = zeros(cfg.n_steps-1, nx);
trace_data.x_plus = zeros(cfg.n_steps-1, nx);
trace_data.nu = zeros(cfg.n_steps-1, ny);
trace_data.trP_minus = zeros(cfg.n_steps-1, 1);
trace_data.trP_plus = zeros(cfg.n_steps-1, 1);
trace_data.min_eig_S = zeros(cfg.n_steps-1, 1);

rng(1);
for k = 2:cfg.n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R);

    trace_data.x_minus(k-1,:) = pred.x_minus.';
    trace_data.x_plus(k-1,:) = upd.x_plus.';
    trace_data.nu(k-1,:) = upd.nu.';
    trace_data.trP_minus(k-1) = trace(pred.P_minus);
    trace_data.trP_plus(k-1) = trace(upd.P_plus);
    trace_data.min_eig_S(k-1) = min(eig(upd.S));

    fs = package_filter_state(upd.x_plus, upd.P_plus);
end

final_err = fs.x_plus - x_truth(end,:).';
pos_rmse_truth = sqrt(mean((trace_data.x_plus(:,1:3) - x_truth(2:end,1:3)).^2, 'all'));

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_1_filter_smoke');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_1_filter_smoke_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_1_filter_smoke_' stamp '.md']);

summary = struct();
summary.n_steps = cfg.n_steps;
summary.final_state_error_norm = norm(final_err);
summary.pos_rmse_truth = pos_rmse_truth;
summary.mean_trP_minus = mean(trace_data.trP_minus);
summary.mean_trP_plus = mean(trace_data.trP_plus);
summary.min_innovation_eig = min(trace_data.min_eig_S);

save(mat_file, 'cfg', 'model', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.1] filter foundation smoke summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.cfg = cfg;
out.model = model;
out.trace_data = trace_data;
out.summary = summary;
out.paths = struct('mat_file', mat_file, 'md_file', md_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, mat_file)
lines = {};
lines{end+1} = '# Phase R8.1 Filter Foundation Smoke';
lines{end+1} = '';
lines{end+1} = '## Summary';
lines{end+1} = '';
lines{end+1} = ['- n_steps = ', num2str(summary.n_steps)];
lines{end+1} = ['- final_state_error_norm = ', num2str(summary.final_state_error_norm, '%.12g')];
lines{end+1} = ['- pos_rmse_truth = ', num2str(summary.pos_rmse_truth, '%.12g')];
lines{end+1} = ['- mean_trP_minus = ', num2str(summary.mean_trP_minus, '%.12g')];
lines{end+1} = ['- mean_trP_plus = ', num2str(summary.mean_trP_plus, '%.12g')];
lines{end+1} = ['- min_innovation_eig = ', num2str(summary.min_innovation_eig, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## Artifact';
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
md = strjoin(lines, newline);
end
