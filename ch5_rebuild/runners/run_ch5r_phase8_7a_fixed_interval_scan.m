function out = run_ch5r_phase8_7a_fixed_interval_scan()
%RUN_CH5R_PHASE8_7A_FIXED_INTERVAL_SCAN
% R8.7a:
%   Scan fixed interval length effect under bubble-oriented metrics.

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

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

interval_list = [10 20 30 40 60];
nI = numel(interval_list);

rows = [];

for ii = 1:nI
    Tin = interval_list(ii);

    trace_obs_fix = resample_selection_trace_fixed_interval( ...
        run_obs.selection_trace, Tin, sprintf('OBS_fixed_%02ds', Tin));
    trace_dwg_fix = resample_selection_trace_fixed_interval( ...
        run_dwg.selection_trace, Tin, sprintf('DWG_fixed_%02ds', Tin));

    m_obs_fix = compute_worst_window_metrics_from_selection_trace( ...
        ch5case, trace_obs_fix, sprintf('OBS_fixed_%02ds', Tin));
    m_dwg_fix = compute_worst_window_metrics_from_selection_trace( ...
        ch5case, trace_dwg_fix, sprintf('DWG_fixed_%02ds', Tin));

    rows = [rows; local_make_row("observability_family", Tin, m_obs_fix)]; %#ok<AGROW>
    rows = [rows; local_make_row("danger_weighted_gain", Tin, m_dwg_fix)]; %#ok<AGROW>
end

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_7a_fixed_interval_scan');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_7a_fixed_interval_scan_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_7a_fixed_interval_scan_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_7a_fixed_interval_scan_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, 'cfg', 'interval_list', 'run_obs', 'run_dwg', 'summary_table');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.7a] fixed interval scan summary ===')
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

function row = local_make_row(policy_family, Tin, m)
row = struct();
row.policy_family = string(policy_family);
row.interval_s = Tin;
row.mean_lambda_min_window = m.summary.mean_lambda_min_window;
row.min_lambda_min_window = m.summary.min_lambda_min_window;
row.worst_window_index = m.summary.worst_window_index;
row.bubble_steps = m.summary.bubble_steps;
row.bubble_time_s = m.summary.bubble_time_s;
row.max_bubble_depth = m.summary.max_bubble_depth;
row.mean_bubble_depth = m.summary.mean_bubble_depth;
row.longest_bubble_span = m.summary.longest_bubble_span;
row.switch_count = m.summary.switch_count;
row.resource_score = m.summary.resource_score;
end

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.7a fixed interval scan';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s, Tin=%g: bubble_steps=%g, max_bubble_depth=%g, longest_bubble_span=%g, mean_lambda=%g, min_lambda=%g, switch_count=%g', ...
        summary_table.policy_family(i), ...
        summary_table.interval_s(i), ...
        summary_table.bubble_steps(i), ...
        summary_table.max_bubble_depth(i), ...
        summary_table.longest_bubble_span(i), ...
        summary_table.mean_lambda_min_window(i), ...
        summary_table.min_lambda_min_window(i), ...
        summary_table.switch_count(i));
end
md = strjoin(lines, newline);
end
