function out = run_ch5r_phase8x_1_window_semantics_audit()
%RUN_CH5R_PHASE8X_1_WINDOW_SEMANTICS_AUDIT
% R8X.1:
%   Audit whether tail-end worst-window phenomenon depends on window semantics.

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

modes = {'forward_truncated', 'forward_full_only', 'centered_full_only'};
policy_names = {'current_method', 'observability_family_online', 'danger_weighted_gain_online'};
policy_traces = {trace_cur, run_obs.selection_trace, run_dwg.selection_trace};

rows = [];
for i = 1:numel(policy_names)
    for j = 1:numel(modes)
        met = compute_window_metrics_with_mode(ch5case, policy_traces{i}, policy_names{i}, modes{j});
        rows = [rows; local_make_row(policy_names{i}, modes{j}, met)]; %#ok<AGROW>
    end
end

summary_table = struct2table(rows);

out_dir = fullfile(base_out, 'phaseR8X_1_window_semantics_audit');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8X_1_window_semantics_audit_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8X_1_window_semantics_audit_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8X_1_window_semantics_audit_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, 'cfg', 'summary_table', 'r5_mat');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8X.1] window semantics audit summary ===')
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

function row = local_make_row(policy_name, mode_name, met)
row = struct();
row.policy_name = string(policy_name);
row.window_mode = string(mode_name);
row.n_valid_windows = met.summary.n_valid_windows;
row.mean_lambda_min_window = met.summary.mean_lambda_min_window;
row.min_lambda_min_window = met.summary.min_lambda_min_window;
row.worst_window_index = met.summary.worst_window_index;
row.bubble_steps = met.summary.bubble_steps;
row.max_bubble_depth = met.summary.max_bubble_depth;
row.longest_bubble_span = met.summary.longest_bubble_span;
row.switch_count = met.summary.switch_count;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8X.1 window semantics audit';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s / %s: n_valid=%g, mean_lambda=%g, min_lambda=%g, worst_window=%g, bubble_steps=%g, max_bubble_depth=%g, longest_bubble_span=%g, switch_count=%g', ...
        summary_table.policy_name(i), ...
        summary_table.window_mode(i), ...
        summary_table.n_valid_windows(i), ...
        summary_table.mean_lambda_min_window(i), ...
        summary_table.min_lambda_min_window(i), ...
        summary_table.worst_window_index(i), ...
        summary_table.bubble_steps(i), ...
        summary_table.max_bubble_depth(i), ...
        summary_table.longest_bubble_span(i), ...
        summary_table.switch_count(i));
end
md = strjoin(lines, newline);
end
