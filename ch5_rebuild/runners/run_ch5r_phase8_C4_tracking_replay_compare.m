function out = run_ch5r_phase8_C4_tracking_replay_compare(varargin)
%RUN_CH5R_PHASE8_C4_TRACKING_REPLAY_COMPARE
% R8-C.4c:
%   - fixed truth source: truth.X only
%   - optional locked input mat files
%   - simple conditioning patch for baseline global DMD replay

opts = struct();
if nargin >= 1 && ~isempty(varargin{1})
    opts = varargin{1};
end

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir  = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r8_dir  = fullfile(base_out, 'phaseR8_C3_outerB_bubble_correction_real_kernel');

if isfield(opts, 'r5_mat_file') && ~isempty(opts.r5_mat_file)
    r5_mat = opts.r5_mat_file;
else
    r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');
end

if isfield(opts, 'r8_mat_file') && ~isempty(opts.r8_mat_file)
    r8_mat = opts.r8_mat_file;
else
    r8_mat = local_find_latest_mat(r8_dir, 'phaseR8_C3_outerB_bubble_correction_real_kernel_*.mat');
end

assert(exist(r5_mat, 'file') == 2, 'Specified R5 mat file not found: %s', r5_mat);
assert(exist(r8_mat, 'file') == 2, 'Specified R8-C.3 mat file not found: %s', r8_mat);

S5 = load(r5_mat);
S8 = load(r8_mat);

assert(isfield(S5, 'selection_trace'), 'R5 mat missing selection_trace.');
assert(isfield(S8, 'selection_trace'), 'R8-C.3 mat missing selection_trace.');

ch5case5 = local_resolve_case_struct(S5, 'R5-real');
local_resolve_case_struct(S8, 'R8-C.3'); %#ok<VUNUS>

rep5 = replay_tracking_koopman_dmd_from_selection_trace(ch5case5, S5.selection_trace, 'R5-real');
rep8 = replay_tracking_koopman_dmd_from_selection_trace(ch5case5, S8.selection_trace, 'R8-C.3');

t_s = ch5case5.t_s(:);

cmp = table( ...
    ["R5-real"; "R8-C.3"], ...
    [rep5.summary.mean_pos_err_norm; rep8.summary.mean_pos_err_norm], ...
    [rep5.summary.mean_rmse_single; rep8.summary.mean_rmse_single], ...
    [rep5.summary.mean_key_abs_supp; rep8.summary.mean_key_abs_supp], ...
    [rep5.summary.mean_key_rel_supp; rep8.summary.mean_key_rel_supp], ...
    [rep5.summary.dmd_ridge_lambda; rep8.summary.dmd_ridge_lambda], ...
    [rep5.summary.dmd_cond_std_gram; rep8.summary.dmd_cond_std_gram], ...
    'VariableNames', { ...
        'policy', ...
        'mean_pos_err_norm', ...
        'mean_rmse_single', ...
        'mean_key_abs_supp', ...
        'mean_key_rel_supp', ...
        'dmd_ridge_lambda', ...
        'dmd_cond_std_gram'});

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
disp('=== [ch5r:R8-C.4c] tracking replay compare summary ===')
disp(cmp)
disp(['R5 input mat        : ' r5_mat])
disp(['R8-C.3 input mat    : ' r8_mat])
disp(['R5 truth source     : ' rep5.summary.truth_source])
disp(['R8 truth source     : ' rep8.summary.truth_source])
disp(['R5 dmd lambda       : ' num2str(rep5.summary.dmd_ridge_lambda, '%.12g')])
disp(['R8 dmd lambda       : ' num2str(rep8.summary.dmd_ridge_lambda, '%.12g')])
disp(['R5 dmd cond         : ' num2str(rep5.summary.dmd_cond_std_gram, '%.12g')])
disp(['R8 dmd cond         : ' num2str(rep8.summary.dmd_cond_std_gram, '%.12g')])
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])
disp(['fig1 file           : ' fig1_file])
disp(['fig2 file           : ' fig2_file])
disp(['fig3 file           : ' fig3_file])

out = struct();
out.compare_table = cmp;
out.inputs = struct( ...
    'r5_mat', r5_mat, ...
    'r8_mat', r8_mat, ...
    'r5_truth_source', rep5.summary.truth_source, ...
    'r8_truth_source', rep8.summary.truth_source);
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

function ch5case = local_resolve_case_struct(S, tag)
if isfield(S, 'ch5case')
    ch5case = S.ch5case;
    return;
end
if isfield(S, 'case')
    ch5case = S.case;
    return;
end
error('Latest %s mat missing both ch5case and case fields.', tag);
end

function md = local_build_md(r5_mat, r8_mat, s5, s8, csv_file, fig1_file, fig2_file, fig3_file)
lines = {};
lines{end+1} = '# Phase R8-C.4c：baseline replay 数值条件化小修';
lines{end+1} = '';
lines{end+1} = '## 1. 固定输入';
lines{end+1} = ['- R5-real mat: `', r5_mat, '`'];
lines{end+1} = ['- R8-C.3 mat: `', r8_mat, '`'];
lines{end+1} = ['- csv summary: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '## 2. 修补口径';
lines{end+1} = '- replay truth source fixed to `truth.X` only.';
lines{end+1} = '- global DMD only.';
lines{end+1} = '- per-dimension standardization + adaptive ridge scale.';
lines{end+1} = '';
lines{end+1} = '## 3. 汇总';
lines{end+1} = ['- R5 mean_pos_err_norm = ', num2str(s5.mean_pos_err_norm, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_pos_err_norm = ', num2str(s8.mean_pos_err_norm, '%.12g')];
lines{end+1} = ['- R5 mean_rmse_single = ', num2str(s5.mean_rmse_single, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_rmse_single = ', num2str(s8.mean_rmse_single, '%.12g')];
lines{end+1} = ['- R5 mean_key_abs_supp = ', num2str(s5.mean_key_abs_supp, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_key_abs_supp = ', num2str(s8.mean_key_abs_supp, '%.12g')];
lines{end+1} = ['- R5 mean_key_rel_supp = ', num2str(s5.mean_key_rel_supp, '%.12g')];
lines{end+1} = ['- R8-C.3 mean_key_rel_supp = ', num2str(s8.mean_key_rel_supp, '%.12g')];
lines{end+1} = ['- R5 dmd_ridge_lambda = ', num2str(s5.dmd_ridge_lambda, '%.12g')];
lines{end+1} = ['- R8-C.3 dmd_ridge_lambda = ', num2str(s8.dmd_ridge_lambda, '%.12g')];
lines{end+1} = ['- R5 dmd_cond_std_gram = ', num2str(s5.dmd_cond_std_gram, '%.12g')];
lines{end+1} = ['- R8-C.3 dmd_cond_std_gram = ', num2str(s8.dmd_cond_std_gram, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 4. 图件';
lines{end+1} = ['- tracking error fig: `', fig1_file, '`'];
lines{end+1} = ['- key-direction absolute suppression fig: `', fig2_file, '`'];
lines{end+1} = ['- key-direction relative suppression fig: `', fig3_file, '`'];

md = strjoin(lines, newline);
end
