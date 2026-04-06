function out = run_ch5r_phase8_6a_avg_vs_worst_compare_fullwindow()
%RUN_CH5R_PHASE8_6A_AVG_VS_WORST_COMPARE_FULLWINDOW

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r8_dir = fullfile(base_out, 'phaseR8_C3_outerB_bubble_correction_real_kernel');

r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');
r8_mat = local_find_latest_mat(r8_dir, 'phaseR8_C3_outerB_bubble_correction_real_kernel_*.mat');

Sr5 = load(r5_mat);
Sr8 = load(r8_mat);

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

cfg.r85f2.parallel.enable = true;
cfg.r85f2.logging.enable = true;
cfg.r85f2.logging.every_k = 240;

cfg.r85f4a.danger_weighted_gain.eta_switch = 1e6;
cfg.r85f4a.danger_weighted_gain.lookahead_steps = 60;
cfg.r85f4a.danger_weighted_gain.alpha_cross = 1e5;
cfg.r85f4a.danger_weighted_gain.beta_margin = 1;
cfg.r85f4a.danger_weighted_gain.eps_margin = 1e-6;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

trace_cur = build_selection_trace_from_generic_trace(Sr5.selection_trace, 'current_method');
trace_new = build_selection_trace_from_generic_trace(Sr8.selection_trace, 'new_bubble_method');

run_pta = run_online_policy_from_pair_bank(cfg, ch5case, 'pta');
run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

mets = {};
mets{end+1} = compute_worst_window_metrics_fullwindow(ch5case, trace_cur, 'current_method');
mets{end+1} = compute_worst_window_metrics_fullwindow(ch5case, trace_new, 'new_bubble_method');
mets{end+1} = compute_worst_window_metrics_fullwindow(ch5case, run_pta.selection_trace, 'PTA_online');
mets{end+1} = compute_worst_window_metrics_fullwindow(ch5case, run_obs.selection_trace, 'observability_family_online');
mets{end+1} = compute_worst_window_metrics_fullwindow(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online');

rows = [];
for i = 1:numel(mets)
    s = mets{i}.summary;
    rows = [rows; struct( ...
        'policy', string(s.tag), ...
        'window_mode', "forward_full_only", ...
        'mean_lambda_min_window', s.mean_lambda_min_window, ...
        'min_lambda_min_window', s.min_lambda_min_window, ...
        'worst_window_index', s.worst_window_index, ...
        'bubble_steps', s.bubble_steps, ...
        'bubble_time_s', s.bubble_time_s, ...
        'max_bubble_depth', s.max_bubble_depth, ...
        'mean_bubble_depth', s.mean_bubble_depth, ...
        'longest_bubble_span', s.longest_bubble_span, ...
        'switch_count', s.switch_count)]; %#ok<AGROW>
end

compare_table = struct2table(rows);

out_dir = fullfile(base_out, 'phaseR8_6a_avg_vs_worst_compare_fullwindow');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_fullwindow_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_fullwindow_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_fullwindow_' stamp '.md']);

writetable(compare_table, csv_file);
save(mat_file, 'compare_table', 'r5_mat', 'r8_mat');

fid = fopen(md_file, 'w');
fprintf(fid, '# R8.6a fullwindow compare\n\n');
fclose(fid);

disp(' ')
disp('=== [ch5r:R8.6a_fullwindow] summary ===')
disp(compare_table)
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.compare_table = compare_table;
out.paths = struct('csv_file', csv_file, 'mat_file', mat_file, 'md_file', md_file, 'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end
