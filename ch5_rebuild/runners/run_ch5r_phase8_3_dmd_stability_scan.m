function out = run_ch5r_phase8_3_dmd_stability_scan()
%RUN_CH5R_PHASE8_3_DMD_STABILITY_SCAN
% Minimal smoke for Phase R8.3:
%   1) build a synthetic truth segment
%   2) fit local DMD models (reg / tsvd)
%   3) predict a short horizon
%   4) compute predicted window Gramian
%   5) output M_G and conditioning diagnostics

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 80;
cfg.lambda_reg = 1e-4;
cfg.rank_trunc = 6;
cfg.window_len = 10;
cfg.r_meas = 1e-2;

nx = 6;
ny = 3;

% Synthetic truth: constant velocity motion
x_truth = zeros(cfg.n_steps, nx);
x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
for k = 2:cfg.n_steps
    x_truth(k,1:3) = x_truth(k-1,1:3) + cfg.dt * x_truth(k-1,4:6);
    x_truth(k,4:6) = x_truth(k-1,4:6);
end

X_prev = x_truth(1:end-1,:).';
X_next = x_truth(2:end,:).';

reg_model = fit_local_dmd_operator_reg(X_prev, X_next, 'lambda_reg', cfg.lambda_reg);
tsvd_model = fit_local_dmd_operator_tsvd(X_prev, X_next, 'rank_trunc', cfg.rank_trunc);
cond_stats = analyze_dmd_conditioning(X_prev);

R = cfg.r_meas * eye(ny);
H_fun = @(x) [eye(3), zeros(3,3)];

x0 = x_truth(end,:).';
x_reg_seq = zeros(nx, cfg.window_len);
x_tsvd_seq = zeros(nx, cfg.window_len);

x_now_reg = x0;
x_now_tsvd = x0;
for ell = 1:cfg.window_len
    x_now_reg = propagate_state_koopman_dmd(reg_model, x_now_reg);
    x_now_tsvd = propagate_state_koopman_dmd(tsvd_model, x_now_tsvd);

    x_reg_seq(:, ell) = x_now_reg;
    x_tsvd_seq(:, ell) = x_now_tsvd;
end

W_reg = compute_predicted_window_gramian(x_reg_seq, H_fun, R);
W_tsvd = compute_predicted_window_gramian(x_tsvd_seq, H_fun, R);

MG_reg = compute_structural_metric_MG(W_reg);
MG_tsvd = compute_structural_metric_MG(W_tsvd);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_3_dmd_stability_scan');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_3_dmd_stability_scan_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_3_dmd_stability_scan_' stamp '.md']);

summary = struct();
summary.n_steps = cfg.n_steps;
summary.window_len = cfg.window_len;
summary.cond_raw = cond_stats.cond_raw;
summary.rank_raw = cond_stats.rank_raw;
summary.MG_reg = MG_reg.M_G;
summary.MG_tsvd = MG_tsvd.M_G;
summary.traceW_reg = MG_reg.trace_W;
summary.traceW_tsvd = MG_tsvd.trace_W;
summary.minEigW_reg = MG_reg.eigvals(1);
summary.minEigW_tsvd = MG_tsvd.eigvals(1);

save(mat_file, 'cfg', 'reg_model', 'tsvd_model', 'cond_stats', ...
    'x_reg_seq', 'x_tsvd_seq', 'W_reg', 'W_tsvd', 'MG_reg', 'MG_tsvd', 'summary');

md = local_build_md(summary, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.3] DMD stability + M_G summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.cfg = cfg;
out.reg_model = reg_model;
out.tsvd_model = tsvd_model;
out.cond_stats = cond_stats;
out.MG_reg = MG_reg;
out.MG_tsvd = MG_tsvd;
out.summary = summary;
out.paths = struct('mat_file', mat_file, 'md_file', md_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, mat_file)
lines = {};
lines{end+1} = '# Phase R8.3 DMD Stability + M_G Scan';
lines{end+1} = '';
lines{end+1} = '## Summary';
lines{end+1} = '';
lines{end+1} = ['- n_steps = ', num2str(summary.n_steps)];
lines{end+1} = ['- window_len = ', num2str(summary.window_len)];
lines{end+1} = ['- cond_raw = ', num2str(summary.cond_raw, '%.12g')];
lines{end+1} = ['- rank_raw = ', num2str(summary.rank_raw, '%.12g')];
lines{end+1} = ['- MG_reg = ', num2str(summary.MG_reg, '%.12g')];
lines{end+1} = ['- MG_tsvd = ', num2str(summary.MG_tsvd, '%.12g')];
lines{end+1} = ['- traceW_reg = ', num2str(summary.traceW_reg, '%.12g')];
lines{end+1} = ['- traceW_tsvd = ', num2str(summary.traceW_tsvd, '%.12g')];
lines{end+1} = ['- minEigW_reg = ', num2str(summary.minEigW_reg, '%.12g')];
lines{end+1} = ['- minEigW_tsvd = ', num2str(summary.minEigW_tsvd, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## Artifact';
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
md = strjoin(lines, newline);
end
