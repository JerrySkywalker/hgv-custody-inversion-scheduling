function out = run_ch5r_phase4_tracking_baseline()
%RUN_CH5R_PHASE4_TRACKING_BASELINE  Minimal R4b.2 tracking-greedy baseline with enhanced logging.

cfg = default_ch5r_params();
ch5case = build_ch5r_case(cfg);
policy = policy_tracking_greedy(cfg, ch5case);

N = numel(ch5case.time_s);
selection_trace = cell(N, 1);
for k = 1:N
    selection_trace{k} = select_satellite_set_tracking_greedy(policy, k);
end

[ch5case_r4_info, gain_trace] = apply_policy_to_info_series(ch5case, selection_trace);

ch5case_r4 = ch5case;
ch5case_r4.info_series = ch5case_r4_info;

wininfo = eval_window_information(ch5case_r4);
bubble = eval_bubble_state(ch5case_r4, wininfo);
state_trace = package_state_trace(ch5case_r4, wininfo, bubble);

phase_like = struct();
phase_like.cfg = cfg;
phase_like.case = ch5case_r4;
phase_like.wininfo = wininfo;
phase_like.bubble = bubble;
phase_like.state_trace = state_trace;
phase_like.ok = true;

result = package_ch5r_result(phase_like, policy, selection_trace);

[policy_log_table, policy_log_summary] = build_tracking_policy_log_table(ch5case_r4, policy, selection_trace, gain_trace, bubble);

out_dir = cfg.ch5r.output_dirs.phaseR4;
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR4_tracking_baseline_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR4_tracking_baseline_' stamp '.md']);
csv_file = fullfile(out_dir, ['phaseR4_tracking_policy_log_' stamp '.csv']);
log_md_file = fullfile(out_dir, ['phaseR4_tracking_policy_log_' stamp '.md']);

writetable(policy_log_table, csv_file);

diag_paths = plot_tracking_policy_diagnostics(policy_log_table, out_dir, stamp);

summary_md = local_build_summary_md(ch5case_r4, policy, result, csv_file, diag_paths);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj1 = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', summary_md);

policy_log_md = summarize_tracking_policy_trace(policy, policy_log_table, policy_log_summary, result);
fid2 = fopen(log_md_file, 'w');
assert(fid2 >= 0, 'Failed to open markdown file: %s', log_md_file);
cleanupObj2 = onCleanup(@() fclose(fid2)); %#ok<NASGU>
fprintf(fid2, '%s', policy_log_md);

save(mat_file, ...
    'cfg', 'ch5case', 'ch5case_r4', 'policy', 'selection_trace', ...
    'gain_trace', 'policy_log_table', 'policy_log_summary', ...
    'wininfo', 'bubble', 'state_trace', 'result', 'diag_paths');

disp(' ')
disp('=== [ch5r:R4] tracking-greedy baseline summary ===')
disp(['policy name          : ' policy.name])
disp(['case id              : ' ch5case_r4.target_case.case_id])
disp(['tau_low              : ' num2str(policy.tau_low, '%.12g')])
disp(['tau_high             : ' num2str(policy.tau_high, '%.12g')])
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(result.cost_metrics.switch_count)])
disp(['resource score       : ' num2str(result.cost_metrics.resource_score, '%.6f')])
disp(['mean gain            : ' num2str(policy_log_summary.mean_gain, '%.12g')])
disp(['csv file             : ' csv_file])
disp(['log md file          : ' log_md_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

assert(strcmp(policy.name, 'tracking_greedy'));
assert(result.cost_metrics.resource_score >= ch5case.theta.Ns, ...
    'R4b.2 expects resource score not below theta_star level.');

if result.cost_metrics.switch_count == 0
    warning('R4b2:NoSwitch', ...
        'Tracking-greedy still has zero switch count. Inspect CSV/diagnostic plots and tau settings.');
end

out = struct();
out.cfg = cfg;
out.case = ch5case_r4;
out.policy = policy;
out.selection_trace = selection_trace;
out.gain_trace = gain_trace;
out.policy_log_table = policy_log_table;
out.policy_log_summary = policy_log_summary;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'csv_file', csv_file, ...
    'log_md_file', log_md_file, ...
    'inst_lambda_png', diag_paths.inst_lambda_png, ...
    'selection_trace_png', diag_paths.selection_trace_png, ...
    'gain_trace_png', diag_paths.gain_trace_png, ...
    'output_dir', out_dir);
out.ok = true;

disp('[ch5r:R4] tracking-greedy baseline passed.')
end

function md = local_build_summary_md(ch5case, policy, result, csv_file, diag_paths)
bm = result.bubble_metrics;
ct = result.cost_metrics;
rq = result.requirement;

lines = {};
lines{end+1} = '# Phase R4 Tracking-Greedy Baseline Summary';
lines{end+1} = '';
lines{end+1} = ['- policy: `', policy.name, '`'];
lines{end+1} = ['- case id: `', ch5case.target_case.case_id, '`'];
lines{end+1} = ['- tau_low: ', num2str(policy.tau_low, '%.12g')];
lines{end+1} = ['- tau_high: ', num2str(policy.tau_high, '%.12g')];
lines{end+1} = ['- bubble_fraction: ', num2str(bm.bubble_fraction, '%.6f')];
lines{end+1} = ['- bubble_time_s: ', num2str(bm.bubble_time_s, '%.6f')];
lines{end+1} = ['- longest_bubble_time_s: ', num2str(bm.longest_bubble_time_s, '%.6f')];
lines{end+1} = ['- max_bubble_depth: ', num2str(bm.max_bubble_depth, '%.12g')];
lines{end+1} = ['- min_margin: ', num2str(rq.min_margin, '%.12g')];
lines{end+1} = ['- switch_count: ', num2str(ct.switch_count)];
lines{end+1} = ['- resource_score: ', num2str(ct.resource_score, '%.6f')];
lines{end+1} = '';
lines{end+1} = '## Log artifacts';
lines{end+1} = '';
lines{end+1} = ['- policy step csv: `', csv_file, '`'];
lines{end+1} = ['- inst lambda plot: `', diag_paths.inst_lambda_png, '`'];
lines{end+1} = ['- selection trace plot: `', diag_paths.selection_trace_png, '`'];
lines{end+1} = ['- gain trace plot: `', diag_paths.gain_trace_png, '`'];
lines{end+1} = '';
lines{end+1} = ['Current note: this R4b.2 run emphasizes diagnosability. ' ...
    'Use the CSV and diagnostic plots to inspect why switching does or does not occur.'];
md = strjoin(lines, newline);
end
