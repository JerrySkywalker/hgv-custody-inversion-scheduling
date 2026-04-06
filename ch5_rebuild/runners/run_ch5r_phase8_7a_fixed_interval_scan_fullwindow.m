function out = run_ch5r_phase8_7a_fixed_interval_scan_fullwindow()
%RUN_CH5R_PHASE8_7A_FIXED_INTERVAL_SCAN_FULLWINDOW

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

run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

interval_list = [10 20 30 40 60];
rows = [];

for i = 1:numel(interval_list)
    Tin = interval_list(i);

    trace_obs = resample_selection_trace_fixed_interval(run_obs.selection_trace, Tin, sprintf('OBS_fixed_%02ds', Tin));
    trace_dwg = resample_selection_trace_fixed_interval(run_dwg.selection_trace, Tin, sprintf('DWG_fixed_%02ds', Tin));

    met_obs = compute_worst_window_metrics_fullwindow(ch5case, trace_obs, sprintf('OBS_fixed_%02ds', Tin));
    met_dwg = compute_worst_window_metrics_fullwindow(ch5case, trace_dwg, sprintf('DWG_fixed_%02ds', Tin));

    rows = [rows; local_make_row("observability_family", Tin, met_obs)]; %#ok<AGROW>
    rows = [rows; local_make_row("danger_weighted_gain", Tin, met_dwg)]; %#ok<AGROW>
end

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_7a_fixed_interval_scan_fullwindow');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_7a_fixed_interval_scan_fullwindow_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_7a_fixed_interval_scan_fullwindow_' stamp '.mat']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table', 'interval_list');

disp(' ')
disp('=== [ch5r:R8.7a_fullwindow] summary ===')
disp(summary_table)

out = struct();
out.summary_table = summary_table;
out.paths = struct('csv_file', csv_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function row = local_make_row(policy_family, Tin, met)
s = met.summary;
row = struct();
row.policy_family = string(policy_family);
row.interval_s = Tin;
row.window_mode = "forward_full_only";
row.mean_lambda_min_window = s.mean_lambda_min_window;
row.min_lambda_min_window = s.min_lambda_min_window;
row.worst_window_index = s.worst_window_index;
row.bubble_steps = s.bubble_steps;
row.max_bubble_depth = s.max_bubble_depth;
row.longest_bubble_span = s.longest_bubble_span;
row.switch_count = s.switch_count;
end
