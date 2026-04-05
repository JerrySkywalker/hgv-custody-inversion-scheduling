function out = run_ch5r_phase8x_2_key_window_ranking_audit()
%RUN_CH5R_PHASE8X_2_KEY_WINDOW_RANKING_AUDIT
% R8X.2:
%   Audit candidate rankings at full-window critical steps.

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r5_mat = local_find_latest_mat(r5_dir, 'phaseR5_bubble_predictive_real_*.mat');
Sr5 = load(r5_mat);
assert(isfield(Sr5, 'selection_trace'), 'R5-real mat missing selection_trace.');

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
run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

met_cur_fwd = compute_window_metrics_with_mode(ch5case, trace_cur, 'current_method', 'forward_full_only');
met_obs_fwd = compute_window_metrics_with_mode(ch5case, run_obs.selection_trace, 'observability_family_online', 'forward_full_only');
met_dwg_fwd = compute_window_metrics_with_mode(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online', 'forward_full_only');

met_cur_ctr = compute_window_metrics_with_mode(ch5case, trace_cur, 'current_method', 'centered_full_only');
met_obs_ctr = compute_window_metrics_with_mode(ch5case, run_obs.selection_trace, 'observability_family_online', 'centered_full_only');
met_dwg_ctr = compute_window_metrics_with_mode(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online', 'centered_full_only');

records = {};
records{end+1} = local_make_record('current_method', 'forward_full_only', met_cur_fwd.summary.worst_window_index, trace_cur);
records{end+1} = local_make_record('observability_family_online', 'forward_full_only', met_obs_fwd.summary.worst_window_index, run_obs.selection_trace);
records{end+1} = local_make_record('danger_weighted_gain_online', 'forward_full_only', met_dwg_fwd.summary.worst_window_index, run_dwg.selection_trace);

records{end+1} = local_make_record('current_method', 'centered_full_only', met_cur_ctr.summary.worst_window_index, trace_cur);
records{end+1} = local_make_record('observability_family_online', 'centered_full_only', met_obs_ctr.summary.worst_window_index, run_obs.selection_trace);
records{end+1} = local_make_record('danger_weighted_gain_online', 'centered_full_only', met_dwg_ctr.summary.worst_window_index, run_dwg.selection_trace);

out_dir = fullfile(base_out, 'phaseR8X_2_key_window_ranking_audit');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));

summary_rows = [];
for i = 1:numel(records)
    rec = records{i};
    tbl = build_candidate_score_table_at_step(ch5case, rec.trace, rec.step_index, cfg.r85f4a.danger_weighted_gain);

    [~, idx_obs] = sort(tbl.obs_score, 'descend');
    [~, idx_pta] = sort(tbl.pta_score, 'descend');
    [~, idx_dng] = sort(tbl.danger_score, 'descend');

    topk = min(5, height(tbl));
    top_obs = tbl(idx_obs(1:topk), :);
    top_pta = tbl(idx_pta(1:topk), :);
    top_dng = tbl(idx_dng(1:topk), :);

    csv_obs = fullfile(out_dir, sprintf('phaseR8X_2_top_obs_%s_%s_k%04d_%s.csv', rec.policy_name, rec.window_mode, rec.step_index, stamp));
    csv_pta = fullfile(out_dir, sprintf('phaseR8X_2_top_pta_%s_%s_k%04d_%s.csv', rec.policy_name, rec.window_mode, rec.step_index, stamp));
    csv_dng = fullfile(out_dir, sprintf('phaseR8X_2_top_dng_%s_%s_k%04d_%s.csv', rec.policy_name, rec.window_mode, rec.step_index, stamp));

    writetable(top_obs, csv_obs);
    writetable(top_pta, csv_pta);
    writetable(top_dng, csv_dng);

    summary_rows = [summary_rows; struct( ...
        'policy_name', string(rec.policy_name), ...
        'window_mode', string(rec.window_mode), ...
        'step_index', rec.step_index, ...
        'n_candidates', height(tbl), ...
        'top_obs_pair', string(sprintf('[%d,%d]', top_obs.pair_sat_1(1), top_obs.pair_sat_2(1))), ...
        'top_pta_pair', string(sprintf('[%d,%d]', top_pta.pair_sat_1(1), top_pta.pair_sat_2(1))), ...
        'top_danger_pair', string(sprintf('[%d,%d]', top_dng.pair_sat_1(1), top_dng.pair_sat_2(1))), ...
        'csv_obs', string(csv_obs), ...
        'csv_pta', string(csv_pta), ...
        'csv_dng', string(csv_dng))]; %#ok<AGROW>
end

summary_table = struct2table(summary_rows);

csv_file = fullfile(out_dir, ['phaseR8X_2_key_window_ranking_audit_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8X_2_key_window_ranking_audit_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8X_2_key_window_ranking_audit_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, 'cfg', 'summary_table', 'r5_mat');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8X.2] key-window ranking audit summary ===')
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

function rec = local_make_record(policy_name, window_mode, step_index, trace)
rec = struct();
rec.policy_name = policy_name;
rec.window_mode = window_mode;
rec.step_index = step_index;
rec.trace = trace;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8X.2 key-window ranking audit';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s / %s / k=%g: n_candidates=%g, top_obs=%s, top_pta=%s, top_danger=%s', ...
        summary_table.policy_name(i), ...
        summary_table.window_mode(i), ...
        summary_table.step_index(i), ...
        summary_table.n_candidates(i), ...
        summary_table.top_obs_pair(i), ...
        summary_table.top_pta_pair(i), ...
        summary_table.top_danger_pair(i));
end
md = strjoin(lines, newline);
end
