function out = run_ch5r_phase8_5f2_online_fullrun_compare()
%RUN_CH5R_PHASE8_5F2_ONLINE_FULLRUN_COMPARE
% R8.5f.2:
%   Online full-run compare framework:
%     1) PTA online
%     2) observability_family online
%     3) current_method (existing online R5 result)
%     4) new_bubble_method (existing online R8-C3 result)

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r8_dir = fullfile(base_out, 'phaseR8_C3_outerB_bubble_correction_real_kernel');

r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');
r8_mat = local_find_latest_mat(r8_dir, 'phaseR8_C3_outerB_bubble_correction_real_kernel_*.mat');

Sr5 = load(r5_mat);
Sr8 = load(r8_mat);

assert(isfield(Sr5, 'selection_trace'), 'R5-real mat missing selection_trace.');
assert(isfield(Sr8, 'selection_trace'), 'R8-C3 mat missing selection_trace.');

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);
cfg.r85f2.parallel.enable = true;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_pta = run_online_policy_from_pair_bank(cfg, ch5case, 'pta');
run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');

trace_cur = build_selection_trace_from_generic_trace(Sr5.selection_trace, 'current_method');
trace_new = build_selection_trace_from_generic_trace(Sr8.selection_trace, 'new_bubble_method');

rep_pta = compute_formal_bubble_metrics_from_selection_trace(ch5case, run_pta.selection_trace, 'PTA_online');
rep_obs = compute_formal_bubble_metrics_from_selection_trace(ch5case, run_obs.selection_trace, 'observability_family_online');
rep_cur = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_cur, 'current_method');
rep_new = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_new, 'new_bubble_method');

compare_table = table( ...
    ["PTA_online"; "observability_family_online"; "current_method"; "new_bubble_method"], ...
    [rep_pta.summary.bubble_steps; rep_obs.summary.bubble_steps; rep_cur.summary.bubble_steps; rep_new.summary.bubble_steps], ...
    [rep_pta.summary.bubble_time_s; rep_obs.summary.bubble_time_s; rep_cur.summary.bubble_time_s; rep_new.summary.bubble_time_s], ...
    [rep_pta.summary.max_bubble_depth; rep_obs.summary.max_bubble_depth; rep_cur.summary.max_bubble_depth; rep_new.summary.max_bubble_depth], ...
    [rep_pta.summary.mean_lambda_min_window; rep_obs.summary.mean_lambda_min_window; rep_cur.summary.mean_lambda_min_window; rep_new.summary.mean_lambda_min_window], ...
    [rep_pta.summary.switch_count; rep_obs.summary.switch_count; rep_cur.summary.switch_count; rep_new.summary.switch_count], ...
    [rep_pta.summary.resource_score; rep_obs.summary.resource_score; rep_cur.summary.resource_score; rep_new.summary.resource_score], ...
    [rep_pta.summary.n_missing_pair_steps; rep_obs.summary.n_missing_pair_steps; rep_cur.summary.n_missing_pair_steps; rep_new.summary.n_missing_pair_steps], ...
    [run_pta.summary.mean_step_time; run_obs.summary.mean_step_time; NaN; NaN], ...
    [run_pta.summary.mean_nPairs; run_obs.summary.mean_nPairs; NaN; NaN], ...
    [double(run_pta.summary.parallel_enabled); double(run_obs.summary.parallel_enabled); NaN; NaN], ...
    'VariableNames', { ...
        'policy', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'max_bubble_depth', ...
        'mean_lambda_min_window', ...
        'switch_count', ...
        'resource_score', ...
        'n_missing_pair_steps', ...
        'mean_step_time', ...
        'mean_nPairs', ...
        'parallel_enabled'});

out_dir = fullfile(base_out, 'phaseR8_5f2_online_fullrun_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_5f2_online_fullrun_compare_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_5f2_online_fullrun_compare_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5f2_online_fullrun_compare_' stamp '.md']);

writetable(compare_table, csv_file);
save(mat_file, 'r5_mat', 'r8_mat', 'run_pta', 'run_obs', 'rep_pta', 'rep_obs', 'rep_cur', 'rep_new', 'compare_table');

md = local_build_md(r5_mat, r8_mat, compare_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5f.2] online full-run compare summary ===')
disp(compare_table)
disp(['R5 input mat         : ' r5_mat])
disp(['R8 input mat         : ' r8_mat])
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.compare_table = compare_table;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function md = local_build_md(r5_mat, r8_mat, compare_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5f.2 online full-run compare';
lines{end+1} = '';
lines{end+1} = ['- R5 input mat = `', r5_mat, '`'];
lines{end+1} = ['- R8 input mat = `', r8_mat, '`'];
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
lines{end+1} = '## compare table';
for i = 1:height(compare_table)
    lines{end+1} = sprintf('- %s: bubble_steps=%g, bubble_time_s=%g, max_bubble_depth=%g, mean_lambda_min_window=%g, switch_count=%g, resource_score=%g, n_missing_pair_steps=%g, mean_step_time=%g, mean_nPairs=%g, parallel_enabled=%g', ...
        compare_table.policy(i), ...
        compare_table.bubble_steps(i), ...
        compare_table.bubble_time_s(i), ...
        compare_table.max_bubble_depth(i), ...
        compare_table.mean_lambda_min_window(i), ...
        compare_table.switch_count(i), ...
        compare_table.resource_score(i), ...
        compare_table.n_missing_pair_steps(i), ...
        compare_table.mean_step_time(i), ...
        compare_table.mean_nPairs(i), ...
        compare_table.parallel_enabled(i));
end
md = strjoin(lines, newline);
end
