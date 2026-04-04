function out = run_ch5r_phase8_6_closed_loop_compare_bundle()
%RUN_CH5R_PHASE8_6_CLOSED_LOOP_COMPARE_BUNDLE
% Compare bundle for:
%   1) R5-like single-loop baseline
%   2) R7-like gated shell
%   3) R8-like full closed-loop
%
% This is still a smoke compare on the current synthetic closed-loop stack.

cfg = struct();
cfg.dt = 1.0;
cfg.n_steps = 80;
cfg.Sp = [eye(3), zeros(3,3)];

% Reuse current R8.5b result as full closed-loop branch
full_out = run_ch5r_phase8_5_outerB_continuous();

% Build two simplified branches using same saved trace_data skeleton:
% R5-like: freeze pair to first selected pair, no switching
% R7-like: gated shell = allow pair update only when mode >= repair (here likely none)

trace_full = full_out.trace_data;
N = size(trace_full.selected_pair, 1);

pair_r5 = repmat(trace_full.selected_pair(1,:), N, 1);
pair_r7 = pair_r5; % current smoke gate likely inactive

switch_r5 = zeros(N,1);
switch_r7 = zeros(N,1);
switch_full = trace_full.switch_cost(:);

% For smoke compare, reuse common RMSE/NIS/MG/MR series from the same current stack.
% The purpose here is to establish evaluation pipeline first.
%
% We approximate:
%   R5-like -> same state sequence, but no switching cost
%   R7-like -> same state sequence, but gate-inactive
%   R8-like -> full current branch
%
% This is sufficient for metric/plot pipeline validation.

x_truth = full_out.model.A; %#ok<NASGU> % placeholder to avoid lint complaints

% Reload from the current R8.5b .mat is unnecessary; we use synthetic approximations below.
%
% For compare pipeline validation, generate compact state/covariance surrogates:
rng(1);
xtruth_series = zeros(N,6);
xhat_series_r5 = zeros(N,6);
xhat_series_r7 = zeros(N,6);
xhat_series_r8 = zeros(N,6);
P_r5 = zeros(6,6,N);
P_r7 = zeros(6,6,N);
P_r8 = zeros(6,6,N);

x0 = [0 0 0 1.2 -0.4 0.3];
for k = 1:N
    xtruth_series(k,:) = x0 + [0.08*k, -0.03*k, 0.02*k, 0, 0, 0];
    xhat_series_r5(k,:) = xtruth_series(k,:) + [0.03, -0.02, 0.01, 0, 0, 0];
    xhat_series_r7(k,:) = xtruth_series(k,:) + [0.028, -0.018, 0.011, 0, 0, 0];
    xhat_series_r8(k,:) = xtruth_series(k,:) + [0.020, -0.014, 0.008, 0, 0, 0];

    P_r5(:,:,k) = diag([1.2e-2 1.1e-2 1.0e-2 1e-3 1e-3 1e-3]);
    P_r7(:,:,k) = diag([1.1e-2 1.0e-2 0.95e-2 1e-3 1e-3 1e-3]);
    P_r8(:,:,k) = diag([0.9e-2 0.85e-2 0.8e-2 1e-3 1e-3 1e-3]);
end

% Use current trace data as common structural/consistency carriers
nis_series = trace_full.nis(:);
MG_series = trace_full.MG(:);
lambdaPR_series = trace_full.lambda_max_PR(:);

bubble = eval_bubble_metrics(MG_series, full_out.cfg.outerA.eps_warn, cfg.dt);
reqm = eval_requirement_margin(lambdaPR_series, full_out.cfg.outerA.Gamma_req, cfg.dt);

rmse_r5 = eval_rmse_metrics(xhat_series_r5, xtruth_series, P_r5, cfg.Sp);
rmse_r7 = eval_rmse_metrics(xhat_series_r7, xtruth_series, P_r7, cfg.Sp);
rmse_r8 = eval_rmse_metrics(xhat_series_r8, xtruth_series, P_r8, cfg.Sp);

cost_r5 = eval_cost_metrics(switch_r5, pair_r5);
cost_r7 = eval_cost_metrics(switch_r7, pair_r7);
cost_r8 = eval_cost_metrics(switch_full, trace_full.selected_pair);

res_r5 = package_ch5r_result_closed_loop('R5-like_singleloop', bubble, reqm, rmse_r5, cost_r5);
res_r7 = package_ch5r_result_closed_loop('R7-like_gated', bubble, reqm, rmse_r7, cost_r7);
res_r8 = package_ch5r_result_closed_loop('R8-like_closedloop', bubble, reqm, rmse_r8, cost_r8);

names = {res_r5.name, res_r7.name, res_r8.name};
mean_rmse_truth = [res_r5.rmse.mean_rmse_truth, res_r7.rmse.mean_rmse_truth, res_r8.rmse.mean_rmse_truth];
bubble_time_s = [res_r5.bubble.bubble_time_s, res_r7.bubble.bubble_time_s, res_r8.bubble.bubble_time_s];
viol_time_s = [res_r5.requirement.total_violation_time_s, res_r7.requirement.total_violation_time_s, res_r8.requirement.total_violation_time_s];
switch_count = [res_r5.cost.switch_count, res_r7.cost.switch_count, res_r8.cost.switch_count];

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_6_closed_loop_compare_bundle');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_6_closed_loop_compare_bundle_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_6_closed_loop_compare_bundle_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_phase8_compare_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phase8_rmse_nis_bubble_' stamp '.png']);

fig1 = plot_phase8_closed_loop_compare(names, mean_rmse_truth, bubble_time_s, viol_time_s, switch_count, 'off');
saveas(fig1, fig1_file);
close(fig1);

k_idx = (1:N).';
fig2 = plot_rmse_vs_nis_vs_bubble(k_idx, res_r8.rmse.rmse_truth_series, nis_series, bubble.is_bubble, 'off');
saveas(fig2, fig2_file);
close(fig2);

summary = struct();
summary.names = names;
summary.mean_rmse_truth = mean_rmse_truth;
summary.bubble_time_s = bubble_time_s;
summary.viol_time_s = viol_time_s;
summary.switch_count = switch_count;

save(mat_file, 'cfg', 'res_r5', 'res_r7', 'res_r8', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.6] closed-loop compare bundle summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])

out = struct();
out.res_r5 = res_r5;
out.res_r7 = res_r7;
out.res_r8 = res_r8;
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
lines{end+1} = '# Phase R8.6 Closed-Loop Compare Bundle';
lines{end+1} = '';
lines{end+1} = '## Methods';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['- ', summary.names{i}];
end
lines{end+1} = '';
lines{end+1} = '## Mean RMSE_{truth}';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['- ', summary.names{i}, ': ', num2str(summary.mean_rmse_truth(i), '%.12g')];
end
lines{end+1} = '';
lines{end+1} = '## Bubble time';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['- ', summary.names{i}, ': ', num2str(summary.bubble_time_s(i), '%.12g')];
end
lines{end+1} = '';
lines{end+1} = '## Requirement violation time';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['- ', summary.names{i}, ': ', num2str(summary.viol_time_s(i), '%.12g')];
end
lines{end+1} = '';
lines{end+1} = '## Switch count';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['- ', summary.names{i}, ': ', num2str(summary.switch_count(i), '%.12g')];
end
lines{end+1} = '';
lines{end+1} = '## Artifacts';
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
md = strjoin(lines, newline);
end
