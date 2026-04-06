function out = run_ch5r_phase8x_3a_case_build_diagnosis()
%RUN_CH5R_PHASE8X_3A_CASE_BUILD_DIAGNOSIS
% R8X.3a:
%   Diagnose whether N01/N02/N03 truly build different cases.

case_list = {'N01','N02','N03'};
rows = [];

for i = 1:numel(case_list)
    info = diagnose_ch5r_case_build(case_list{i});

    rows = [rows; struct( ...
        'requested_case_id', string(info.requested_case_id), ...
        'cfg_case_id', string(local_to_text(info.cfg_case_id)), ...
        'cfg_scenario_case_id', string(local_to_text(info.cfg_scenario_case_id)), ...
        'cfg_target_case_id', string(local_to_text(info.cfg_target_case_id)), ...
        'base_case_case_id', string(local_to_text(info.base_case_case_id)), ...
        'base_case_case_name', string(local_to_text(info.base_case_case_name)), ...
        'truth_n_steps', info.truth_n_steps, ...
        'truth_t_start', info.truth_t_start, ...
        'truth_t_end', info.truth_t_end, ...
        'pair_bank_n_steps', info.pair_bank_n_steps, ...
        'truth_first_pos_sig', string(local_vec_text(info.truth_first_pos)), ...
        'truth_last_pos_sig', string(local_vec_text(info.truth_last_pos)), ...
        'truth_first_vel_sig', string(local_vec_text(info.truth_first_vel)), ...
        'truth_last_vel_sig', string(local_vec_text(info.truth_last_vel)))]; %#ok<AGROW>
end

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8X_3a_case_build_diagnosis');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8X_3a_case_build_diagnosis_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8X_3a_case_build_diagnosis_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8X_3a_case_build_diagnosis_' stamp '.md']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table', 'case_list');

md = local_build_md(summary_table, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8X.3a] case build diagnosis summary ===')
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

function s = local_vec_text(v)
if isempty(v)
    s = '';
else
    s = sprintf('%.6g,', v);
    s = s(1:end-1);
end
end

function s = local_to_text(v)
if isempty(v)
    s = '';
elseif isstring(v)
    s = char(v);
elseif ischar(v)
    s = v;
elseif isnumeric(v) && isscalar(v)
    s = num2str(v);
else
    s = class(v);
end
end

function md = local_build_md(summary_table, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8X.3a case build diagnosis';
lines{end+1} = '';
lines{end+1} = ['- csv file = `', csv_file, '`'];
lines{end+1} = ['- mat file = `', mat_file, '`'];
lines{end+1} = '';
for i = 1:height(summary_table)
    lines{end+1} = sprintf('- req=%s, cfg=%s, base_case=%s/%s, n_steps=%g, t=[%g,%g], pair_bank=%g, first_pos=%s, last_pos=%s', ...
        summary_table.requested_case_id(i), ...
        summary_table.cfg_case_id(i), ...
        summary_table.base_case_case_id(i), ...
        summary_table.base_case_case_name(i), ...
        summary_table.truth_n_steps(i), ...
        summary_table.truth_t_start(i), ...
        summary_table.truth_t_end(i), ...
        summary_table.pair_bank_n_steps(i), ...
        summary_table.truth_first_pos_sig(i), ...
        summary_table.truth_last_pos_sig(i));
end
md = strjoin(lines, newline);
end
