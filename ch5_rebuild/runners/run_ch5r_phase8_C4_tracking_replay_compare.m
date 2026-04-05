function out = run_ch5r_phase8_C4_tracking_replay_compare()
%RUN_CH5R_PHASE8_C4_TRACKING_REPLAY_COMPARE
% R8-C.4:
%   replay tracking with Koopman-DMD under latest R5-real and latest R8-C.3 selection traces,
%   then output:
%     - tracking error curve
%     - key-direction covariance suppression curves
%     - compare summary

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir  = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r8_dir  = fullfile(base_out, 'phaseR8_C3_outerB_bubble_correction_real_kernel');

r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');
r8_mat = local_find_latest_mat(r8_dir, 'phaseR8_C3_outerB_bubble_correction_real_kernel_*.mat');

S5 = load(r5_mat);
S8 = load(r8_mat);

assert(isfield(S5, 'ch5case') && isfield(S5, 'selection_trace'), 'Latest R5 mat missing ch5case or selection_trace.');
assert(isfield(S8, 'case') && isfield(S8, 'selection_trace'), 'Latest R8-C.3 mat missing case or selection_trace.');

ch5case = S5.ch5case;
rep5 = replay_tracking_koopman_dmd_from_selection_trace(ch5case, S5.selection_trace, 'R5-real');
rep8 = replay_tracking_koopman_dmd_from_selection_trace(ch5case, S8.selection_trace, 'R8-C.3');

t_s = ch5case.t_s(:);

cmp = table( ...
    ["R5-real"; "R8-C.3"], ...
    [rep5.summary.mean_pos_err_norm; rep8.summary.mean_pos_err_norm], ...
    [rep5.summary.mean_rmse_single; rep8.summary.mean_rmse_single], ...
    [rep5.summary.mean_key_abs_supp; rep8.summary.mean_key_abs_supp], ...
    [rep5.summary.mean_key_rel_supp; rep8.summary.mean_key_rel_supp], ...
    'VariableNames', { ...
        'policy', ...
        'mean_pos_err_norm', ...
        'mean_rmse_single', ...
        'mean_key_abs_supp', ...
        'mean_key_rel_supp'});

out_dir = fullfile(base_out, 'phaseR8_C4_tracking_replay_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_C4_tracking_replay_compare_' stamp '.csv']);
md_file  = fullfile(out_dir, ['phaseR8_C4_tracking_replay_compare_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR8_C4_tracking_replay_compare_' stamp '.mat']);
fig1_file = fullfile(out_dir, ['plot_phaseR8_C4_tracking_error_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phaseR8_C4_key_abs_supp_' stamp '.png']);
fig3_file = fullfile(out_dir, ['plot_phaseR8_C4_key_rel_supp_' stamp '.png']);

writetable(cmp, csv_file);

fig1 = plot_compare_tracking_error_curves(t_s, rep5.pos_err_norm, rep8.pos_err_norm, "R5-real", "R8-C.3", 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_compare_keydir_suppression_curves(t_s, rep5.key_abs_supp, rep8.key_abs_supp, "R5-real", "R8-C.3", ...
    'key-direction abs suppression', 'key-direction covariance absolute suppression', 'off');
saveas(fig2, fig2_file);
close(fig2);

fig3 = plot_compare_keydir_suppression_curves(t_s, rep5.key_rel_supp, rep8.key_rel_supp, "R5-real", "R8-C.3", ...
    'key-direction rel suppression', 'key-direction covariance relative suppression', 'off');
saveas(fig3, fig3_file);
close(fig3);

md = local_build_md(r5_mat, r8_mat, rep5.summary, rep8.summary, csv_file, fig1_file, fig2_file, fig3_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'r5_mat', 'r8_mat', 'rep5', 'rep8', 'cmp');

disp(' ')
disp('=== [ch5r:R8-C.4] tracking replay compare summary ===')
disp(cmp)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])
disp(['fig1 file           : ' fig1_file])
disp(['fig2 file           : ' fig2_file])
disp(['fig3 file           : ' fig3_file])

out = struct();
out.compare_table = cmp;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'md_file', md_file, ...
    'mat_file', mat_file, ...
    'fig1_file', fig1_file, ...
    'fig2_file', fig2_file, ...
    'fig3_file', fig3_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function md = local_build_md(r5_mat, r8_mat, s5, s8, csv_file, fig1_file, fig2_file, fig3_file)
lines = {};
lines{end+1} = '# Phase R8-C.4：Koopman-DMD 跟踪回放 + RMSE/关键方向协方差抑制对比';
lines{end+1} = '';
lines{end+1} = '## 1. 数据来源';
lines{end+1} = ['- R5-real latest mat: `', r5_mat, '`'];
lines{end+1} = ['- R8-C.3 latest mat: `', r8_mat, '`'];
lines{end+1} = ['- csv summary: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '## 2. 口径固定';
lines{end+1} = '- 使用相同 `ch5case` 与相同 Koopman-DMD replay filter。';
lines{end+1} = '- 位置误差曲线：`position error norm = ||r_hat - r_truth||_2`。';
lines{end+1} = '- 单次运行 RMSE 型指标：`mean_rmse_single = sqrt(mean(rmse_single(k)^2))`。';
lines{end+1} = '- 关键方向抑制量：沿 `P_r^-` 最大特征方向的 pre/post 协方差压缩。';
lines{end+1} = '';
lines{end+1} = '## 3. 汇总';
lines{end+1} = '';
lines{end+1} = ['- R5 mean_pos_err_norm = ', num2str(s5.mean_pos_err_norm, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_pos_err_norm = ', num2str(s8.mean_pos_err_norm, '%.12g')];
lines{end+1} = ['- R5 mean_rmse_single = ', num2str(s5.mean_rmse_single, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_rmse_single = ', num2str(s8.mean_rmse_single, '%.12g')];
lines{end+1} = ['- R5 mean_key_abs_supp = ', num2str(s5.mean_key_abs_supp, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_key_abs_supp = ', num2str(s8.mean_key_abs_supp, '%.12g')];
lines{end+1} = ['- R5 mean_key_rel_supp = ', num2str(s5.mean_key_rel_supp, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_key_rel_supp = ', num2str(s8.mean_key_rel_supp, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 4. 图件';
lines{end+1} = ['- tracking error fig: `', fig1_file, '`'];
lines{end+1} = ['- key-direction absolute suppression fig: `', fig2_file, '`'];
lines{end+1} = ['- key-direction relative suppression fig: `', fig3_file, '`'];

md = strjoin(lines, newline);
end
