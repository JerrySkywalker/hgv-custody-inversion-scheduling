function out = run_ch5r_phase8_5c_stepwise_selection_scan()
%RUN_CH5R_PHASE8_5C_STEPWISE_SELECTION_SCAN
% R8.5c.3:
%   Full-horizon stepwise scan for Li-style four relay-selection criteria.
%
% Outputs:
%   - candidate count at each step
%   - selected pair of PTA / CN / detY_rim / detY_fast at each step
%   - disagreement statistics

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

li_case = build_r85_li_case_from_current_case(cfg);
n_steps = li_case.meta.n_steps;

candidate_count = zeros(n_steps,1);
selected_pta = NaN(n_steps,2);
selected_cn = NaN(n_steps,2);
selected_detY_rim = NaN(n_steps,2);
selected_detY_fast = NaN(n_steps,2);

sat_field_path = "";
tgt_field_path = "";

for k = 1:n_steps
    candidates = build_r85_pair_candidates_from_case(li_case, k);
    candidate_count(k) = numel(candidates);

    if isempty(candidates)
        continue;
    end

    if strlength(sat_field_path) == 0
        sat_field_path = candidates(1).sat_field_path;
    end
    if strlength(tgt_field_path) == 0
        tgt_field_path = candidates(1).tgt_field_path;
    end

    out_pta = li_select_by_criterion(candidates, 'pta');
    out_cn = li_select_by_criterion(candidates, 'cn');
    out_rim = li_select_by_criterion(candidates, 'detY_rim');
    out_fast = li_select_by_criterion(candidates, 'detY_fast');

    selected_pta(k,:) = out_pta.best_candidate.sat_pair;
    selected_cn(k,:) = out_cn.best_candidate.sat_pair;
    selected_detY_rim(k,:) = out_rim.best_candidate.sat_pair;
    selected_detY_fast(k,:) = out_fast.best_candidate.sat_pair;
end

valid_mask = candidate_count > 0;
multi_mask = candidate_count > 1;

pta_vs_cn_diff = local_pair_diff_mask(selected_pta, selected_cn) & valid_mask;
pta_vs_rim_diff = local_pair_diff_mask(selected_pta, selected_detY_rim) & valid_mask;
pta_vs_fast_diff = local_pair_diff_mask(selected_pta, selected_detY_fast) & valid_mask;
cn_vs_rim_diff = local_pair_diff_mask(selected_cn, selected_detY_rim) & valid_mask;
cn_vs_fast_diff = local_pair_diff_mask(selected_cn, selected_detY_fast) & valid_mask;
rim_vs_fast_diff = local_pair_diff_mask(selected_detY_rim, selected_detY_fast) & valid_mask;

summary = struct();
summary.phase_name = "R8.5c.3";
summary.n_steps = n_steps;
summary.sat_field_path = sat_field_path;
summary.tgt_field_path = tgt_field_path;
summary.n_valid_steps = sum(valid_mask);
summary.n_multi_candidate_steps = sum(multi_mask);
summary.max_candidate_count = max(candidate_count);
summary.first_valid_step = local_first_true_index(valid_mask);
summary.first_multi_candidate_step = local_first_true_index(multi_mask);
summary.n_pta_vs_cn_diff = sum(pta_vs_cn_diff);
summary.n_pta_vs_rim_diff = sum(pta_vs_rim_diff);
summary.n_pta_vs_fast_diff = sum(pta_vs_fast_diff);
summary.n_cn_vs_rim_diff = sum(cn_vs_rim_diff);
summary.n_cn_vs_fast_diff = sum(cn_vs_fast_diff);
summary.n_rim_vs_fast_diff = sum(rim_vs_fast_diff);

scan_table = table( ...
    (1:n_steps)', ...
    candidate_count, ...
    selected_pta(:,1), selected_pta(:,2), ...
    selected_cn(:,1), selected_cn(:,2), ...
    selected_detY_rim(:,1), selected_detY_rim(:,2), ...
    selected_detY_fast(:,1), selected_detY_fast(:,2), ...
    valid_mask, ...
    multi_mask, ...
    pta_vs_cn_diff, ...
    pta_vs_rim_diff, ...
    pta_vs_fast_diff, ...
    cn_vs_rim_diff, ...
    cn_vs_fast_diff, ...
    rim_vs_fast_diff, ...
    'VariableNames', { ...
        'step_index', ...
        'candidate_count', ...
        'pta_sat1', 'pta_sat2', ...
        'cn_sat1', 'cn_sat2', ...
        'rim_sat1', 'rim_sat2', ...
        'fast_sat1', 'fast_sat2', ...
        'has_candidate', ...
        'has_multi_candidate', ...
        'pta_vs_cn_diff', ...
        'pta_vs_rim_diff', ...
        'pta_vs_fast_diff', ...
        'cn_vs_rim_diff', ...
        'cn_vs_fast_diff', ...
        'rim_vs_fast_diff'});

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5c_stepwise_selection_scan');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_5c_stepwise_selection_scan_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_5c_stepwise_selection_scan_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5c_stepwise_selection_scan_' stamp '.md']);

writetable(scan_table, csv_file);
save(mat_file, 'cfg', 'li_case', 'summary', 'scan_table', ...
    'candidate_count', 'selected_pta', 'selected_cn', 'selected_detY_rim', 'selected_detY_fast');

md = local_build_md(summary, csv_file, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5c.3] Li-style stepwise selection scan summary ===')
disp(summary)
disp('--- first valid rows ---')
disp(scan_table(scan_table.has_candidate, 1:min(10,sum(scan_table.has_candidate)), :))
disp(['csv file             : ' csv_file])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.summary = summary;
out.scan_table = scan_table;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function tf = local_pair_diff_mask(A, B)
tf = false(size(A,1),1);
for k = 1:size(A,1)
    a = A(k,:);
    b = B(k,:);
    if any(isnan(a)) || any(isnan(b))
        tf(k) = false;
    else
        tf(k) = any(a ~= b);
    end
end
end

function idx = local_first_true_index(mask)
hit = find(mask, 1, 'first');
if isempty(hit)
    idx = NaN;
else
    idx = hit;
end
end

function md = local_build_md(summary, csv_file, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5c.3 Li-style stepwise selection scan';
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
lines{end+1} = '';
lines{end+1} = ['- csv file: `', csv_file, '`'];
lines{end+1} = ['- mat file: `', mat_file, '`'];
md = strjoin(lines, newline);
end
