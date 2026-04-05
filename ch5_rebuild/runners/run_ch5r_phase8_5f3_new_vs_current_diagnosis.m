function out = run_ch5r_phase8_5f3_new_vs_current_diagnosis()
%RUN_CH5R_PHASE8_5F3_NEW_VS_CURRENT_DIAGNOSIS
% R8.5f.3:
%   Explain why new_bubble_method may switch more but fail to reduce bubble.

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
li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

trace_cur = build_selection_trace_from_generic_trace(Sr5.selection_trace, 'current_method');
trace_new = build_selection_trace_from_generic_trace(Sr8.selection_trace, 'new_bubble_method');

diag = analyze_policy_difference_window_effect(ch5case, trace_cur, trace_new, 'current_method', 'new_bubble_method');

out_dir = fullfile(base_out, 'phaseR8_5f3_new_vs_current_diagnosis');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_5f3_new_vs_current_diagnosis_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_5f3_new_vs_current_diagnosis_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5f3_new_vs_current_diagnosis_' stamp '.md']);

writetable(diag.diff_table, csv_file);
save(mat_file, 'r5_mat', 'r8_mat', 'diag');

md = local_build_md(r5_mat, r8_mat, diag.summary, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5f.3] new vs current diagnosis summary ===')
disp(diag.summary)
disp('--- first changed rows ---')
changed_rows = diag.diff_table(diag.diff_table.pair_diff, :);
disp(changed_rows(1:min(10,height(changed_rows)), :))
disp(['R5 input mat         : ' r5_mat])
disp(['R8 input mat         : ' r8_mat])
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.summary = diag.summary;
out.diff_table = diag.diff_table;
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

function md = local_build_md(r5_mat, r8_mat, summary, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5f.3 new vs current diagnosis';
lines{end+1} = '';
lines{end+1} = ['- R5 input mat = `', r5_mat, '`'];
lines{end+1} = ['- R8 input mat = `', r8_mat, '`'];
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
fns = fieldnames(summary);
for i = 1:numel(fns)
    v = summary.(fns{i});
    if isstring(v) && isscalar(v)
        lines{end+1} = ['- ', fns{i}, ' = ', char(v)];
    elseif isnumeric(v) && isscalar(v)
        lines{end+1} = ['- ', fns{i}, ' = ', num2str(v, '%.12g')];
    end
end
md = strjoin(lines, newline);
end
