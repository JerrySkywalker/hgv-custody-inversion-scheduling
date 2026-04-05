function out = run_ch5r_phase8_5c_real_candidate_smoke()
%RUN_CH5R_PHASE8_5C_REAL_CANDIDATE_SMOKE
% R8.5c.2 fixed:
%   scan steps automatically and choose a step with the largest number of valid pair candidates.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

li_case = build_r85_li_case_from_current_case(cfg);

[step_index, candidates] = local_find_best_step_with_candidates(li_case);

assert(~isempty(candidates), 'No valid 2-satellite candidates found in the scanned horizon.');

out_pta      = li_select_by_criterion(candidates, 'pta');
out_cn       = li_select_by_criterion(candidates, 'cn');
out_detY_rim = li_select_by_criterion(candidates, 'detY_rim');
out_detY_fast= li_select_by_criterion(candidates, 'detY_fast');

summary = struct();
summary.phase_name = "R8.5c.2";
summary.step_index = step_index;
summary.n_candidates = numel(candidates);
summary.sat_field_path = string(candidates(1).sat_field_path);
summary.tgt_field_path = string(candidates(1).tgt_field_path);
summary.best_pta_pair = string(local_pair_to_text(out_pta.best_candidate.sat_pair));
summary.best_cn_pair = string(local_pair_to_text(out_cn.best_candidate.sat_pair));
summary.best_detY_rim_pair = string(local_pair_to_text(out_detY_rim.best_candidate.sat_pair));
summary.best_detY_fast_pair = string(local_pair_to_text(out_detY_fast.best_candidate.sat_pair));

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5c_real_candidate_smoke');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_5c_real_candidate_smoke_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5c_real_candidate_smoke_' stamp '.md']);

save(mat_file, 'cfg', 'li_case', 'candidates', 'out_pta', 'out_cn', 'out_detY_rim', 'out_detY_fast', 'summary');

md = local_build_md(summary, candidates, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5c.2] Li-style real-candidate smoke summary ===')
disp(summary)
disp('--- top 10 candidates table ---')
disp(local_candidates_table_head(candidates, 10))
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.li_case = li_case;
out.candidates = candidates;
out.summary = summary;
out.by_pta = out_pta;
out.by_cn = out_cn;
out.by_detY_rim = out_detY_rim;
out.by_detY_fast = out_detY_fast;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function [best_step, best_candidates] = local_find_best_step_with_candidates(li_case)
n_steps = li_case.meta.n_steps;

best_step = NaN;
best_candidates = [];
best_n = -1;

for k = 1:n_steps
    cand_k = build_r85_pair_candidates_from_case(li_case, k);
    nk = numel(cand_k);
    if nk > best_n
        best_n = nk;
        best_step = k;
        best_candidates = cand_k;
    end
end
end

function txt = local_pair_to_text(pair)
txt = sprintf('[%d,%d]', pair(1), pair(2));
end

function T = local_candidates_table_head(candidates, n_head)
n = min(numel(candidates), n_head);
T = struct2table(candidates(1:n));
end

function md = local_build_md(summary, candidates, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5c.2 Li-style real candidate smoke';
lines{end+1} = '';
lines{end+1} = ['- phase_name = ', char(summary.phase_name)];
lines{end+1} = ['- step_index = ', num2str(summary.step_index)];
lines{end+1} = ['- n_candidates = ', num2str(summary.n_candidates)];
lines{end+1} = ['- sat_field_path = ', char(summary.sat_field_path)];
lines{end+1} = ['- tgt_field_path = ', char(summary.tgt_field_path)];
lines{end+1} = ['- best_pta_pair = ', char(summary.best_pta_pair)];
lines{end+1} = ['- best_cn_pair = ', char(summary.best_cn_pair)];
lines{end+1} = ['- best_detY_rim_pair = ', char(summary.best_detY_rim_pair)];
lines{end+1} = ['- best_detY_fast_pair = ', char(summary.best_detY_fast_pair)];
lines{end+1} = '';
lines{end+1} = '## first candidates';
for i = 1:min(8, numel(candidates))
    lines{end+1} = sprintf('- pair=%s, PTA=%.6g, CN=%.6g, detY_rim=%.6g, detY_fast=%.6g', ...
        local_pair_to_text(candidates(i).sat_pair), ...
        candidates(i).pta_len_s, ...
        candidates(i).cn_value, ...
        candidates(i).detY_rim_value, ...
        candidates(i).detY_fast_value);
end
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
md = strjoin(lines, newline);
end
