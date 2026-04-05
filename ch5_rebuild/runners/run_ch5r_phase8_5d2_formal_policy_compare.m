function out = run_ch5r_phase8_5d2_formal_policy_compare()
%RUN_CH5R_PHASE8_5D2_FORMAL_POLICY_COMPARE
% R8.5d.2:
%   Compare PTA / observability_family / current_method
%   on formal windowed lambda_min(Y_W) bubble chain.

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

scan_dir = fullfile(base_out, 'phaseR8_5c_stepwise_selection_scan');
r5_dir = fullfile(base_out, 'phaseR5_bubble_predictive_real');

scan_mat = local_find_latest_mat(scan_dir, 'phaseR8_5c_stepwise_selection_scan_*.mat');
r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');

Sscan = load(scan_mat);
Sr5 = load(r5_mat);

assert(isfield(Sscan, 'scan_table'), 'R8.5c.5 mat missing scan_table.');
assert(isfield(Sr5, 'selection_trace'), 'R5-real mat missing selection_trace.');

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);
li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

trace_pta = build_selection_trace_from_scan_table(Sscan.scan_table, 'pta');
trace_obs = build_selection_trace_from_scan_table(Sscan.scan_table, 'observability_family');
trace_cur = build_selection_trace_from_r5_trace(Sr5.selection_trace);

rep_pta = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_pta, 'PTA');
rep_obs = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_obs, 'observability_family');
rep_cur = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_cur, 'current_method');

compare_table = table( ...
    ["PTA"; "observability_family"; "current_method"], ...
    [rep_pta.summary.bubble_steps; rep_obs.summary.bubble_steps; rep_cur.summary.bubble_steps], ...
    [rep_pta.summary.bubble_time_s; rep_obs.summary.bubble_time_s; rep_cur.summary.bubble_time_s], ...
    [rep_pta.summary.max_bubble_depth; rep_obs.summary.max_bubble_depth; rep_cur.summary.max_bubble_depth], ...
    [rep_pta.summary.mean_lambda_min_window; rep_obs.summary.mean_lambda_min_window; rep_cur.summary.mean_lambda_min_window], ...
    [rep_pta.summary.switch_count; rep_obs.summary.switch_count; rep_cur.summary.switch_count], ...
    [rep_pta.summary.resource_score; rep_obs.summary.resource_score; rep_cur.summary.resource_score], ...
    [rep_pta.summary.n_missing_pair_steps; rep_obs.summary.n_missing_pair_steps; rep_cur.summary.n_missing_pair_steps], ...
    'VariableNames', { ...
        'policy', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'max_bubble_depth', ...
        'mean_lambda_min_window', ...
        'switch_count', ...
        'resource_score', ...
        'n_missing_pair_steps'});

out_dir = fullfile(base_out, 'phaseR8_5d2_formal_policy_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_5d2_formal_policy_compare_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_5d2_formal_policy_compare_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5d2_formal_policy_compare_' stamp '.md']);

writetable(compare_table, csv_file);
save(mat_file, 'scan_mat', 'r5_mat', 'rep_pta', 'rep_obs', 'rep_cur', 'compare_table');

md = local_build_md(scan_mat, r5_mat, compare_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5d.2] formal policy compare summary ===')
disp(compare_table)
disp(['scan input mat       : ' scan_mat])
disp(['R5 input mat         : ' r5_mat])
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

function md = local_build_md(scan_mat, r5_mat, compare_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5d.2 formal policy compare';
lines{end+1} = '';
lines{end+1} = ['- scan input mat = `', scan_mat, '`'];
lines{end+1} = ['- R5 input mat = `', r5_mat, '`'];
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
lines{end+1} = '## compare table';
for i = 1:height(compare_table)
    lines{end+1} = sprintf('- %s: bubble_steps=%g, bubble_time_s=%g, max_bubble_depth=%g, mean_lambda_min_window=%g, switch_count=%g, resource_score=%g, n_missing_pair_steps=%g', ...
        compare_table.policy(i), ...
        compare_table.bubble_steps(i), ...
        compare_table.bubble_time_s(i), ...
        compare_table.max_bubble_depth(i), ...
        compare_table.mean_lambda_min_window(i), ...
        compare_table.switch_count(i), ...
        compare_table.resource_score(i), ...
        compare_table.n_missing_pair_steps(i));
end
md = strjoin(lines, newline);
end
