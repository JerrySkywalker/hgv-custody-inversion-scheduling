function out = run_ch5r_phase8_6b_critical_window_diagnosis_fullwindow()
%RUN_CH5R_PHASE8_6B_CRITICAL_WINDOW_DIAGNOSIS_FULLWINDOW

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

items = {
    'current_method', trace_cur;
    'new_bubble_method', trace_new;
    'PTA_online', run_pta.selection_trace;
    'observability_family_online', run_obs.selection_trace;
    'danger_weighted_gain_online', run_dwg.selection_trace
    };

half_width = 20;
rows = [];

for i = 1:size(items,1)
    tag = items{i,1};
    trace = items{i,2};
    met = compute_worst_window_metrics_fullwindow(ch5case, trace, tag);

    idx0 = met.summary.worst_window_index;
    k1 = max(1, idx0-half_width);
    k2 = min(numel(met.lambda_series), idx0+half_width);

    rows = [rows; struct( ...
        'policy', string(tag), ...
        'window_mode', "forward_full_only", ...
        'worst_window_index', idx0, ...
        'window_start', k1, ...
        'window_end', k2, ...
        'min_lambda_min_window', met.summary.min_lambda_min_window, ...
        'max_bubble_depth', met.summary.max_bubble_depth, ...
        'longest_bubble_span', met.summary.longest_bubble_span)]; %#ok<AGROW>
end

summary_table = struct2table(rows);

out_dir = fullfile(base_out, 'phaseR8_6b_critical_window_diagnosis_fullwindow');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_6b_critical_window_diagnosis_fullwindow_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_6b_critical_window_diagnosis_fullwindow_' stamp '.mat']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table', 'r5_mat', 'r8_mat');

disp(' ')
disp('=== [ch5r:R8.6b_fullwindow] summary ===')
disp(summary_table)

out = struct();
out.summary_table = summary_table;
out.paths = struct('csv_file', csv_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end
