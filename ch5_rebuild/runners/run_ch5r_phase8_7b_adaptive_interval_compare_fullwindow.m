function out = run_ch5r_phase8_7b_adaptive_interval_compare_fullwindow()
%RUN_CH5R_PHASE8_7B_ADAPTIVE_INTERVAL_COMPARE_FULLWINDOW

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

cfg.r87b.adaptive.T_long = 60;
cfg.r87b.adaptive.T_mid = 20;
cfg.r87b.adaptive.T_short = 10;
cfg.r87b.adaptive.tau1 = 0.02;
cfg.r87b.adaptive.tau2 = 0.10;
cfg.r87b.adaptive.tau_emg = 0.02;
cfg.r87b.adaptive.eps_risk = 1e-6;
cfg.r87b.adaptive.guard_margin = 3000;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

m_obs_step = compute_worst_window_metrics_fullwindow(ch5case, run_obs.selection_trace, 'OBS_stepwise');
m_dwg_step = compute_worst_window_metrics_fullwindow(ch5case, run_dwg.selection_trace, 'DWG_stepwise');

trace_obs_fix60 = resample_selection_trace_fixed_interval(run_obs.selection_trace, 60, 'OBS_fixed_60');
trace_dwg_fix60 = resample_selection_trace_fixed_interval(run_dwg.selection_trace, 60, 'DWG_fixed_60');

m_obs_fix60 = compute_worst_window_metrics_fullwindow(ch5case, trace_obs_fix60, 'OBS_fixed_60');
m_dwg_fix60 = compute_worst_window_metrics_fullwindow(ch5case, trace_dwg_fix60, 'DWG_fixed_60');

sch_obs = build_adaptive_refresh_schedule_from_risk(m_obs_step.lambda_series, m_obs_step.summary.gamma_req, cfg.r87b.adaptive);
sch_dwg = build_adaptive_refresh_schedule_from_risk(m_dwg_step.lambda_series, m_dwg_step.summary.gamma_req, cfg.r87b.adaptive);

trace_obs_adp = resample_selection_trace_adaptive_interval(run_obs.selection_trace, sch_obs.refresh_mask, 'OBS_adaptive');
trace_dwg_adp = resample_selection_trace_adaptive_interval(run_dwg.selection_trace, sch_dwg.refresh_mask, 'DWG_adaptive');

m_obs_adp = compute_worst_window_metrics_fullwindow(ch5case, trace_obs_adp, 'OBS_adaptive');
m_dwg_adp = compute_worst_window_metrics_fullwindow(ch5case, trace_dwg_adp, 'DWG_adaptive');

ss_obs = compute_schedule_statistics(sch_obs.refresh_mask, sch_obs.interval_schedule);
ss_dwg = compute_schedule_statistics(sch_dwg.refresh_mask, sch_dwg.interval_schedule);

rows = [];
rows = [rows; local_make_row("observability_family", "stepwise", m_obs_step, NaN, NaN, NaN)]; %#ok<AGROW>
rows = [rows; local_make_row("observability_family", "fixed_60", m_obs_fix60, NaN, 60, 0)]; %#ok<AGROW>
rows = [rows; local_make_row("observability_family", "adaptive", m_obs_adp, ss_obs.refresh_count, ss_obs.mean_realized_interval, ss_obs.n_early_refresh)]; %#ok<AGROW>
rows = [rows; local_make_row("danger_weighted_gain", "stepwise", m_dwg_step, NaN, NaN, NaN)]; %#ok<AGROW>
rows = [rows; local_make_row("danger_weighted_gain", "fixed_60", m_dwg_fix60, NaN, 60, 0)]; %#ok<AGROW>
rows = [rows; local_make_row("danger_weighted_gain", "adaptive", m_dwg_adp, ss_dwg.refresh_count, ss_dwg.mean_realized_interval, ss_dwg.n_early_refresh)]; %#ok<AGROW>

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_7b_adaptive_interval_compare_fullwindow');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_7b_adaptive_interval_compare_fullwindow_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_7b_adaptive_interval_compare_fullwindow_' stamp '.mat']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table');

disp(' ')
disp('=== [ch5r:R8.7b_fullwindow] summary ===')
disp(summary_table)

out = struct();
out.summary_table = summary_table;
out.paths = struct('csv_file', csv_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function row = local_make_row(policy_family, schedule_mode, met, refresh_count, mean_realized_interval, n_early_refresh)
s = met.summary;
row = struct();
row.policy_family = string(policy_family);
row.schedule_mode = string(schedule_mode);
row.window_mode = "forward_full_only";
row.refresh_count = refresh_count;
row.mean_realized_interval = mean_realized_interval;
row.n_early_refresh = n_early_refresh;
row.mean_lambda_min_window = s.mean_lambda_min_window;
row.min_lambda_min_window = s.min_lambda_min_window;
row.worst_window_index = s.worst_window_index;
row.bubble_steps = s.bubble_steps;
row.max_bubble_depth = s.max_bubble_depth;
row.longest_bubble_span = s.longest_bubble_span;
row.switch_count = s.switch_count;
end
