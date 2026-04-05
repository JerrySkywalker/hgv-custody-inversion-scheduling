function out = run_ch5r_phase8_6a_avg_vs_worst_compare()
%RUN_CH5R_PHASE8_6A_AVG_VS_WORST_COMPARE
% R8.6a:
%   Unified compare table for average metrics vs worst-window metrics.

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
cfg.r85f2.logging.enable = true;
cfg.r85f2.logging.every_k = 80;

cfg.r85f4a.danger_weighted_gain.eta_switch = 1e6;
cfg.r85f4a.danger_weighted_gain.lookahead_steps = 60;
cfg.r85f4a.danger_weighted_gain.alpha_cross = 1e5;
cfg.r85f4a.danger_weighted_gain.beta_margin = 1;
cfg.r85f4a.danger_weighted_gain.eps_margin = 1e-6;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_pta = run_online_policy_from_pair_bank(cfg, ch5case, 'pta');
run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

trace_cur = build_selection_trace_from_generic_trace(Sr5.selection_trace, 'current_method');
trace_new = build_selection_trace_from_generic_trace(Sr8.selection_trace, 'new_bubble_method');

m_cur = compute_worst_window_metrics_from_selection_trace(ch5case, trace_cur, 'current_method');
m_new = compute_worst_window_metrics_from_selection_trace(ch5case, trace_new, 'new_bubble_method');
m_pta = compute_worst_window_metrics_from_selection_trace(ch5case, run_pta.selection_trace, 'PTA_online');
m_obs = compute_worst_window_metrics_from_selection_trace(ch5case, run_obs.selection_trace, 'observability_family_online');
m_dwg = compute_worst_window_metrics_from_selection_trace(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online');

compare_table = table( ...
    ["current_method"; "new_bubble_method"; "PTA_online"; "observability_family_online"; "danger_weighted_gain_online"], ...
    [m_cur.summary.mean_lambda_min_window; m_new.summary.mean_lambda_min_window; m_pta.summary.mean_lambda_min_window; m_obs.summary.mean_lambda_min_window; m_dwg.summary.mean_lambda_min_window], ...
    [m_cur.summary.median_lambda_min_window; m_new.summary.median_lambda_min_window; m_pta.summary.median_lambda_min_window; m_obs.summary.median_lambda_min_window; m_dwg.summary.median_lambda_min_window], ...
    [m_cur.summary.min_lambda_min_window; m_new.summary.min_lambda_min_window; m_pta.summary.min_lambda_min_window; m_obs.summary.min_lambda_min_window; m_dwg.summary.min_lambda_min_window], ...
    [m_cur.summary.worst_window_index; m_new.summary.worst_window_index; m_pta.summary.worst_window_index; m_obs.summary.worst_window_index; m_dwg.summary.worst_window_index], ...
    [m_cur.summary.bubble_steps; m_new.summary.bubble_steps; m_pta.summary.bubble_steps; m_obs.summary.bubble_steps; m_dwg.summary.bubble_steps], ...
    [m_cur.summary.bubble_time_s; m_new.summary.bubble_time_s; m_pta.summary.bubble_time_s; m_obs.summary.bubble_time_s; m_dwg.summary.bubble_time_s], ...
    [m_cur.summary.max_bubble_depth; m_new.summary.max_bubble_depth; m_pta.summary.max_bubble_depth; m_obs.summary.max_bubble_depth; m_dwg.summary.max_bubble_depth], ...
    [m_cur.summary.mean_bubble_depth; m_new.summary.mean_bubble_depth; m_pta.summary.mean_bubble_depth; m_obs.summary.mean_bubble_depth; m_dwg.summary.mean_bubble_depth], ...
    [m_cur.summary.longest_bubble_span; m_new.summary.longest_bubble_span; m_pta.summary.longest_bubble_span; m_obs.summary.longest_bubble_span; m_dwg.summary.longest_bubble_span], ...
    [m_cur.summary.switch_count; m_new.summary.switch_count; m_pta.summary.switch_count; m_obs.summary.switch_count; m_dwg.summary.switch_count], ...
    [m_cur.summary.resource_score; m_new.summary.resource_score; m_pta.summary.resource_score; m_obs.summary.resource_score; m_dwg.summary.resource_score], ...
    [m_cur.summary.n_missing_pair_steps; m_new.summary.n_missing_pair_steps; m_pta.summary.n_missing_pair_steps; m_obs.summary.n_missing_pair_steps; m_dwg.summary.n_missing_pair_steps], ...
    'VariableNames', { ...
        'policy', ...
        'mean_lambda_min_window', ...
        'median_lambda_min_window', ...
        'min_lambda_min_window', ...
        'worst_window_index', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'max_bubble_depth', ...
        'mean_bubble_depth', ...
        'longest_bubble_span', ...
        'switch_count', ...
        'resource_score', ...
        'n_missing_pair_steps'});

meta = struct();
meta.r5_mat = r5_mat;
meta.r8_mat = r8_mat;
meta.eta_switch = cfg.r85f4a.danger_weighted_gain.eta_switch;
meta.lookahead_steps = cfg.r85f4a.danger_weighted_gain.lookahead_steps;
meta.alpha_cross = cfg.r85f4a.danger_weighted_gain.alpha_cross;
meta.beta_margin = cfg.r85f4a.danger_weighted_gain.beta_margin;
meta.eps_margin = cfg.r85f4a.danger_weighted_gain.eps_margin;

out_dir = fullfile(base_out, 'phaseR8_6a_avg_vs_worst_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_6a_avg_vs_worst_compare_' stamp '.md']);

writetable(compare_table, csv_file);
save(mat_file, ...
    'cfg', 'meta', ...
    'run_pta', 'run_obs', 'run_dwg', ...
    'm_cur', 'm_new', 'm_pta', 'm_obs', 'm_dwg', ...
    'compare_table');

md = local_build_md(compare_table, meta, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.6a] average vs worst-window compare summary ===')
disp(compare_table)
disp('=== meta ===')
disp(meta)
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.compare_table = compare_table;
out.meta = meta;
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

function md = local_build_md(compare_table, meta, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.6a average vs worst-window compare';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
lines{end+1} = '## meta';
mfn = fieldnames(meta);
for i = 1:numel(mfn)
    v = meta.(mfn{i});
    if ischar(v)
        lines{end+1} = ['- ', mfn{i}, ' = `', v, '`'];
    elseif isstring(v) && isscalar(v)
        lines{end+1} = ['- ', mfn{i}, ' = `', char(v), '`'];
    elseif isnumeric(v) && isscalar(v)
        lines{end+1} = ['- ', mfn{i}, ' = ', num2str(v, '%.12g')];
    end
end
lines{end+1} = '';
lines{end+1} = '## compare table';
for i = 1:height(compare_table)
    lines{end+1} = sprintf('- %s: mean_lambda=%g, min_lambda=%g, worst_window=%g, bubble_steps=%g, max_bubble_depth=%g, longest_bubble_span=%g, switch_count=%g', ...
        compare_table.policy(i), ...
        compare_table.mean_lambda_min_window(i), ...
        compare_table.min_lambda_min_window(i), ...
        compare_table.worst_window_index(i), ...
        compare_table.bubble_steps(i), ...
        compare_table.max_bubble_depth(i), ...
        compare_table.longest_bubble_span(i), ...
        compare_table.switch_count(i));
end
md = strjoin(lines, newline);
end
