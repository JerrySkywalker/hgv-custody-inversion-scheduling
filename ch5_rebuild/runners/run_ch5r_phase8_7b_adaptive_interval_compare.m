function out = run_ch5r_phase8_7b_adaptive_interval_compare()
%RUN_CH5R_PHASE8_7B_ADAPTIVE_INTERVAL_COMPARE
% R8.7b:
%   Compare stepwise / fixed-60 / adaptive interval on N01 single case.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

cfg.r85f2.parallel.enable = true;
cfg.r85f2.logging.enable = true;
cfg.r85f2.logging.every_k = 200;

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
cfg.r87b.adaptive.eps_risk = 1e-6;
cfg.r87b.adaptive.guard_margin = 3000;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

m_obs_step = compute_worst_window_metrics_from_selection_trace(ch5case, run_obs.selection_trace, 'OBS_stepwise');
m_dwg_step = compute_worst_window_metrics_from_selection_trace(ch5case, run_dwg.selection_trace, 'DWG_stepwise');

trace_obs_fix60 = resample_selection_trace_fixed_interval(run_obs.selection_trace, 60, 'OBS_fixed_60');
trace_dwg_fix60 = resample_selection_trace_fixed_interval(run_dwg.selection_trace, 60, 'DWG_fixed_60');

m_obs_fix60 = compute_worst_window_metrics_from_selection_trace(ch5case, trace_obs_fix60, 'OBS_fixed_60');
m_dwg_fix60 = compute_worst_window_metrics_from_selection_trace(ch5case, trace_dwg_fix60, 'DWG_fixed_60');

sch_obs = build_adaptive_refresh_schedule_from_risk(m_obs_step.lambda_series, m_obs_step.summary.gamma_req, cfg.r87b.adaptive);
sch_dwg = build_adaptive_refresh_schedule_from_risk(m_dwg_step.lambda_series, m_dwg_step.summary.gamma_req, cfg.r87b.adaptive);

trace_obs_adp = resample_selection_trace_adaptive_interval(run_obs.selection_trace, sch_obs.refresh_mask, 'OBS_adaptive');
trace_dwg_adp = resample_selection_trace_adaptive_interval(run_dwg.selection_trace, sch_dwg.refresh_mask, 'DWG_adaptive');

m_obs_adp = compute_worst_window_metrics_from_selection_trace(ch5case, trace_obs_adp, 'OBS_adaptive');
m_dwg_adp = compute_worst_window_metrics_from_selection_trace(ch5case, trace_dwg_adp, 'DWG_adaptive');

ss_obs = compute_schedule_statistics(sch_obs.refresh_mask, sch_obs.interval_schedule);
ss_dwg = compute_schedule_statistics(sch_dwg.refresh_mask, sch_dwg.interval_schedule);

rows = [];
rows = [rows; local_make_row("observability_family", "stepwise", m_obs_step, NaN, NaN)]; %#ok<AGROW>
rows = [rows; local_make_row("observability_family", "fixed_60", m_obs_fix60, NaN, 60)]; %#ok<AGROW>
rows = [rows; local_make_row("observability_family", "adaptive", m_obs_adp, ss_obs.refresh_count, ss_obs.mean_interval)]; %#ok<AGROW>

rows = [rows; local_make_row("danger_weighted_gain", "stepwise", m_dwg_step, NaN, NaN)]; %#ok<AGROW>
rows = [rows; local_make_row("danger_weighted_gain", "fixed_60", m_dwg_fix60, NaN, 60)]; %#ok<AGROW>
rows = [rows; local_make_row("danger_weighted_gain", "adaptive", m_dwg_adp, ss_dwg.refresh_count, ss_dwg.mean_interval)]; %#ok<AGROW>

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_7b_adaptive_interval_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_7b_adaptive_interval_compare_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_7b_adaptive_interval_compare_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_7b_adaptive_interval_compare_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, ...
    'cfg', 'summary_table', ...
    'run_obs', 'run_dwg', ...
    'm_obs_step', 'm_dwg_step', ...
    'm_obs_fix60', 'm_dwg_fix60', ...
    'm_obs_adp', 'm_dwg_adp', ...
    'sch_obs', 'sch_dwg', ...
    'ss_obs', 'ss_dwg');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.7b] adaptive interval compare summary ===')
disp(summary_table)
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.summary_table = summary_table;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function row = local_make_row(policy_family, schedule_mode, m, refresh_count, mean_interval)
row = struct();
row.policy_family = string(policy_family);
row.schedule_mode = string(schedule_mode);
row.refresh_count = refresh_count;
row.mean_interval = mean_interval;
row.mean_lambda_min_window = m.summary.mean_lambda_min_window;
row.min_lambda_min_window = m.summary.min_lambda_min_window;
row.worst_window_index = m.summary.worst_window_index;
row.bubble_steps = m.summary.bubble_steps;
row.bubble_time_s = m.summary.bubble_time_s;
row.max_bubble_depth = m.summary.max_bubble_depth;
row.mean_bubble_depth = m.summary.mean_bubble_depth;
row.longest_bubble_span = m.summary.longest_bubble_span;
row.switch_count = m.summary.switch_count;
end

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.7b adaptive interval compare';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s / %s: refresh_count=%g, mean_interval=%g, bubble_steps=%g, max_bubble_depth=%g, longest_bubble_span=%g, mean_lambda=%g, min_lambda=%g, switch_count=%g', ...
        summary_table.policy_family(i), ...
        summary_table.schedule_mode(i), ...
        summary_table.refresh_count(i), ...
        summary_table.mean_interval(i), ...
        summary_table.bubble_steps(i), ...
        summary_table.max_bubble_depth(i), ...
        summary_table.longest_bubble_span(i), ...
        summary_table.mean_lambda_min_window(i), ...
        summary_table.min_lambda_min_window(i), ...
        summary_table.switch_count(i));
end
md = strjoin(lines, newline);
end
