function out = run_ch5r_phase8_5f4a_danger_gain_compare()
%RUN_CH5R_PHASE8_5F4A_DANGER_GAIN_COMPARE
% R8.5f.4b:
%   Compare PTA / observability_family / danger_weighted_gain
%   under online full-run + formal bubble chain.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

cfg.r85f2.parallel.enable = true;
cfg.r85f2.logging.enable = true;
cfg.r85f2.logging.every_k = 40;

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

rep_pta = compute_formal_bubble_metrics_from_selection_trace(ch5case, run_pta.selection_trace, 'PTA_online');
rep_obs = compute_formal_bubble_metrics_from_selection_trace(ch5case, run_obs.selection_trace, 'observability_family_online');
rep_dwg = compute_formal_bubble_metrics_from_selection_trace(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online');

compare_table = table( ...
    ["PTA_online"; "observability_family_online"; "danger_weighted_gain_online"], ...
    [rep_pta.summary.bubble_steps; rep_obs.summary.bubble_steps; rep_dwg.summary.bubble_steps], ...
    [rep_pta.summary.bubble_time_s; rep_obs.summary.bubble_time_s; rep_dwg.summary.bubble_time_s], ...
    [rep_pta.summary.max_bubble_depth; rep_obs.summary.max_bubble_depth; rep_dwg.summary.max_bubble_depth], ...
    [rep_pta.summary.mean_lambda_min_window; rep_obs.summary.mean_lambda_min_window; rep_dwg.summary.mean_lambda_min_window], ...
    [rep_pta.summary.switch_count; rep_obs.summary.switch_count; rep_dwg.summary.switch_count], ...
    [run_pta.summary.mean_step_time; run_obs.summary.mean_step_time; run_dwg.summary.mean_step_time], ...
    [run_pta.summary.mean_nPairs; run_obs.summary.mean_nPairs; run_dwg.summary.mean_nPairs], ...
    [double(run_pta.summary.parallel_enabled); double(run_obs.summary.parallel_enabled); double(run_dwg.summary.parallel_enabled)], ...
    'VariableNames', { ...
        'policy', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'max_bubble_depth', ...
        'mean_lambda_min_window', ...
        'switch_count', ...
        'mean_step_time', ...
        'mean_nPairs', ...
        'parallel_enabled'});

meta = struct();
meta.eta_switch = cfg.r85f4a.danger_weighted_gain.eta_switch;
meta.lookahead_steps = cfg.r85f4a.danger_weighted_gain.lookahead_steps;
meta.alpha_cross = cfg.r85f4a.danger_weighted_gain.alpha_cross;
meta.beta_margin = cfg.r85f4a.danger_weighted_gain.beta_margin;
meta.eps_margin = cfg.r85f4a.danger_weighted_gain.eps_margin;

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5f4a_danger_gain_compare');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_5f4a_danger_gain_compare_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_5f4a_danger_gain_compare_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5f4a_danger_gain_compare_' stamp '.md']);

writetable(compare_table, csv_file);
save(mat_file, 'cfg', 'meta', 'run_pta', 'run_obs', 'run_dwg', 'rep_pta', 'rep_obs', 'rep_dwg', 'compare_table');

md = local_build_md(compare_table, meta, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5f.4b] threshold-crossing gain compare summary ===')
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

function md = local_build_md(compare_table, meta, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5f.4b threshold-crossing gain compare';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
lines{end+1} = '## meta';
mfn = fieldnames(meta);
for i = 1:numel(mfn)
    lines{end+1} = ['- ', mfn{i}, ' = ', num2str(meta.(mfn{i}), '%.12g')];
end
lines{end+1} = '';
for i = 1:height(compare_table)
    lines{end+1} = sprintf('- %s: bubble_steps=%g, bubble_time_s=%g, max_bubble_depth=%g, mean_lambda_min_window=%g, switch_count=%g, mean_step_time=%g, mean_nPairs=%g, parallel_enabled=%g', ...
        compare_table.policy(i), ...
        compare_table.bubble_steps(i), ...
        compare_table.bubble_time_s(i), ...
        compare_table.max_bubble_depth(i), ...
        compare_table.mean_lambda_min_window(i), ...
        compare_table.switch_count(i), ...
        compare_table.mean_step_time(i), ...
        compare_table.mean_nPairs(i), ...
        compare_table.parallel_enabled(i));
end
md = strjoin(lines, newline);
end
