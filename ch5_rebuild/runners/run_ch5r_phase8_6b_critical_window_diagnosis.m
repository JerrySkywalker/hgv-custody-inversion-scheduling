function out = run_ch5r_phase8_6b_critical_window_diagnosis()
%RUN_CH5R_PHASE8_6B_CRITICAL_WINDOW_DIAGNOSIS
% R8.6b:
%   Diagnose local neighborhood around each policy's worst window.

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
cfg.r85f2.logging.every_k = 120;

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

half_width = 20;

nb(1) = extract_worst_window_neighborhood(ch5case, trace_cur, 'current_method', half_width); %#ok<AGROW>
nb(2) = extract_worst_window_neighborhood(ch5case, trace_new, 'new_bubble_method', half_width); %#ok<AGROW>
nb(3) = extract_worst_window_neighborhood(ch5case, run_pta.selection_trace, 'PTA_online', half_width); %#ok<AGROW>
nb(4) = extract_worst_window_neighborhood(ch5case, run_obs.selection_trace, 'observability_family_online', half_width); %#ok<AGROW>
nb(5) = extract_worst_window_neighborhood(ch5case, run_dwg.selection_trace, 'danger_weighted_gain_online', half_width); %#ok<AGROW>

for i = 1:numel(nb)
    nb(i).tag = char(nb(i).summary.tag);
end

policy = string({nb.tag})';
worst_window_index = [nb.idx0]';
window_start = [nb.k1]';
window_end = [nb.k2]';
min_lambda_min_window = arrayfun(@(s) s.summary.min_lambda_min_window, nb)';
max_bubble_depth = arrayfun(@(s) s.summary.max_bubble_depth, nb)';
longest_bubble_span = arrayfun(@(s) s.summary.longest_bubble_span, nb)';

summary_table = table( ...
    policy, ...
    worst_window_index, ...
    window_start, ...
    window_end, ...
    min_lambda_min_window, ...
    max_bubble_depth, ...
    longest_bubble_span, ...
    'VariableNames', { ...
        'policy', ...
        'worst_window_index', ...
        'window_start', ...
        'window_end', ...
        'min_lambda_min_window', ...
        'max_bubble_depth', ...
        'longest_bubble_span'});

out_dir = fullfile(base_out, 'phaseR8_6b_critical_window_diagnosis');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));

csv_file = fullfile(out_dir, ['phaseR8_6b_summary_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_6b_critical_window_diagnosis_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_6b_critical_window_diagnosis_' stamp '.md']);

writetable(summary_table, csv_file);

for i = 1:numel(nb)
    local_csv = fullfile(out_dir, ['phaseR8_6b_local_' nb(i).tag '_' stamp '.csv']);
    writetable(nb(i).local_table, local_csv);
    nb(i).local_csv = local_csv;
end

fig1_file = plot_worst_window_lambda_series(nb, out_dir, stamp);
fig2_file = plot_worst_window_bubble_depth_series(nb, out_dir, stamp);
fig3_file = plot_worst_window_pair_trace(nb, out_dir, stamp);

save(mat_file, 'cfg', 'summary_table', 'nb', 'run_pta', 'run_obs', 'run_dwg', 'r5_mat', 'r8_mat');

md = local_build_md(summary_table, nb, csv_file, fig1_file, fig2_file, fig3_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.6b] critical worst-window diagnosis summary ===')
disp(summary_table)
disp('--- first rows: danger_weighted_gain_online local table ---')
disp(nb(5).local_table(1:min(10,height(nb(5).local_table)), :))
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])
disp(['fig3 file            : ' fig3_file])

out = struct();
out.summary_table = summary_table;
out.nb = nb;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'fig1_file', fig1_file, ...
    'fig2_file', fig2_file, ...
    'fig3_file', fig3_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files under %s', dir_path);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function md = local_build_md(summary_table, nb, csv_file, fig1_file, fig2_file, fig3_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.6b critical worst-window diagnosis';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = ['- fig1 file = `', fig1_file, '`'];
lines{end+1} = ['- fig2 file = `', fig2_file, '`'];
lines{end+1} = ['- fig3 file = `', fig3_file, '`'];
lines{end+1} = '';
lines{end+1} = '## summary table';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- %s: worst_window=%g, local_range=[%g,%g], min_lambda=%g, max_bubble_depth=%g, longest_bubble_span=%g', ...
        summary_table.policy(i), ...
        summary_table.worst_window_index(i), ...
        summary_table.window_start(i), ...
        summary_table.window_end(i), ...
        summary_table.min_lambda_min_window(i), ...
        summary_table.max_bubble_depth(i), ...
        summary_table.longest_bubble_span(i));
end
lines{end+1} = '';
lines{end+1} = '## local csv files';
for i = 1:numel(nb)
    lines{end+1} = ['- ', nb(i).tag, ': `', nb(i).local_csv, '`'];
end
md = strjoin(lines, newline);
end
