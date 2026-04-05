function out = run_ch5r_phase8x_3_multi_case_window_audit()
%RUN_CH5R_PHASE8X_3_MULTI_CASE_WINDOW_AUDIT
% R8X.3:
%   Parallel window semantics audit for N01/N02/N03.

case_list = {'N01','N02','N03'};
modes = {'forward_truncated', 'forward_full_only', 'centered_full_only'};

rows = [];

for ic = 1:numel(case_list)
    case_id = case_list{ic};

    cfg = default_ch5r_params(true);
    cfg = default_ch5r_r85_li_methods_params(cfg);
    cfg = set_case_id_for_ch5r(cfg, case_id);

    cfg.r85f2.parallel.enable = true;
    cfg.r85f2.logging.enable = true;
    cfg.r85f2.logging.every_k = 320;

    cfg.r85f4a.danger_weighted_gain.eta_switch = 1e6;
    cfg.r85f4a.danger_weighted_gain.lookahead_steps = 60;
    cfg.r85f4a.danger_weighted_gain.alpha_cross = 1e5;
    cfg.r85f4a.danger_weighted_gain.beta_margin = 1;
    cfg.r85f4a.danger_weighted_gain.eps_margin = 1e-6;

    li_case = build_r85_li_case_from_current_case(cfg);
    ch5case = li_case.base_case;

    run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
    run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

    for im = 1:numel(modes)
        mode_name = modes{im};

        met_obs = compute_window_metrics_with_mode(ch5case, run_obs.selection_trace, [case_id '_OBS'], mode_name);
        met_dwg = compute_window_metrics_with_mode(ch5case, run_dwg.selection_trace, [case_id '_DWG'], mode_name);

        rows = [rows; local_make_row(case_id, 'observability_family_online', mode_name, met_obs)]; %#ok<AGROW>
        rows = [rows; local_make_row(case_id, 'danger_weighted_gain_online', mode_name, met_dwg)]; %#ok<AGROW>
    end
end

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8X_3_multi_case_window_audit');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8X_3_multi_case_window_audit_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8X_3_multi_case_window_audit_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8X_3_multi_case_window_audit_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table', 'case_list', 'modes');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8X.3] multi-case window audit summary ===')
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

function row = local_make_row(case_id, policy_name, mode_name, met)
row = struct();
row.case_id = string(case_id);
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

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8X.3 multi-case window audit';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s / %s / %s: n_valid=%g, mean_lambda=%g, min_lambda=%g, worst_window=%g, bubble_steps=%g, max_bubble_depth=%g, longest_bubble_span=%g', ...
        summary_table.case_id(i), ...
        summary_table.policy_name(i), ...
        summary_table.window_mode(i), ...
        summary_table.n_valid_windows(i), ...
        summary_table.mean_lambda_min_window(i), ...
        summary_table.min_lambda_min_window(i), ...
        summary_table.worst_window_index(i), ...
        summary_table.bubble_steps(i), ...
        summary_table.max_bubble_depth(i), ...
        summary_table.longest_bubble_span(i));
end
md = strjoin(lines, newline);
end
