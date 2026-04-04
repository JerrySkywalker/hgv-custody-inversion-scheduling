function out = run_ch5r_phase8_6_closed_loop_compare_bundle()
%RUN_CH5R_PHASE8_6_CLOSED_LOOP_COMPARE_BUNDLE
% R8.6-real:
%   compare true independently-run branches
%   1) singleloop real
%   2) gated real
%   3) closedloop real

cfg = struct();
cfg.dt = 1.0;
cfg.Sp = [eye(3), zeros(3,3)];

b1 = run_ch5r_phase8_branch_singleloop_real();
b2 = run_ch5r_phase8_branch_gated_real();
b3 = run_ch5r_phase8_branch_closedloop_real();

branches = {b1, b2, b3};
results = cell(1,3);

for i = 1:3
    b = branches{i};
    td = b.trace_data;

    bubble = eval_bubble_metrics(td.MG, b.cfg.outerA.eps_warn, cfg.dt);
    reqm = eval_requirement_margin(td.lambda_max_PR, b.cfg.outerA.Gamma_req, cfg.dt);
    rmse = eval_rmse_metrics(td.xhat_plus_series, td.xtruth_series, td.Pplus_series, cfg.Sp);
    cost = eval_cost_metrics(td.switch_cost, td.selected_pair);

    results{i} = package_ch5r_result_closed_loop(b.name, bubble, reqm, rmse, cost);
end

res_r5 = results{1};
res_r7 = results{2};
res_r8 = results{3};

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

k_idx = (1:size(b3.trace_data.xtruth_series,1)).';
fig2 = plot_rmse_vs_nis_vs_bubble(k_idx, res_r8.rmse.rmse_truth_series, b3.trace_data.nis, res_r8.bubble.is_bubble, 'off');
saveas(fig2, fig2_file);
close(fig2);

summary = struct();
summary.names = names;
summary.mean_rmse_truth = mean_rmse_truth;
summary.mean_rmse_cov = [res_r5.rmse.mean_rmse_cov, res_r7.rmse.mean_rmse_cov, res_r8.rmse.mean_rmse_cov];
summary.bubble_time_s = bubble_time_s;
summary.viol_time_s = viol_time_s;
summary.switch_count = switch_count;

save(mat_file, 'res_r5', 'res_r7', 'res_r8', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.6-real] closed-loop compare bundle summary ===')
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
lines{end+1} = '# Phase R8.6-real Closed-Loop Compare Bundle';
lines{end+1} = '';
for i = 1:numel(summary.names)
    lines{end+1} = ['## ', summary.names{i}];
    lines{end+1} = ['- mean RMSE truth = ', num2str(summary.mean_rmse_truth(i), '%.12g')];
    lines{end+1} = ['- mean RMSE cov = ', num2str(summary.mean_rmse_cov(i), '%.12g')];
    lines{end+1} = ['- bubble time = ', num2str(summary.bubble_time_s(i), '%.12g')];
    lines{end+1} = ['- req violation time = ', num2str(summary.viol_time_s(i), '%.12g')];
    lines{end+1} = ['- switch count = ', num2str(summary.switch_count(i), '%.12g')];
    lines{end+1} = '';
end
lines{end+1} = '## Artifacts';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
md = strjoin(lines, newline);
end
