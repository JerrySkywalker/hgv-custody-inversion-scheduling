function out = run_ch5r_phase8_5c_selection_smoke()
%RUN_CH5R_PHASE8_5C_SELECTION_SMOKE
% R8.5c.1:
%   Deterministic smoke validation for Li-style four relay-selection criteria.
%
% This step does NOT yet use real visible-satellite candidate generation.
% It only validates criterion interface and ranking direction.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

candidates = local_build_smoke_candidates();

out_pta      = li_select_by_criterion(candidates, 'pta');
out_cn       = li_select_by_criterion(candidates, 'cn');
out_detY_rim = li_select_by_criterion(candidates, 'detY_rim');
out_detY_fast= li_select_by_criterion(candidates, 'detY_fast');

summary = struct();
summary.phase_name = "R8.5c.1";
summary.n_candidates = numel(candidates);
summary.best_pta_pair = string(local_pair_to_text(out_pta.best_candidate.sat_pair));
summary.best_cn_pair = string(local_pair_to_text(out_cn.best_candidate.sat_pair));
summary.best_detY_rim_pair = string(local_pair_to_text(out_detY_rim.best_candidate.sat_pair));
summary.best_detY_fast_pair = string(local_pair_to_text(out_detY_fast.best_candidate.sat_pair));

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5c_selection_smoke');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_5c_selection_smoke_' stamp '.mat']);
md_file  = fullfile(out_dir, ['phaseR8_5c_selection_smoke_' stamp '.md']);

save(mat_file, 'cfg', 'candidates', 'out_pta', 'out_cn', 'out_detY_rim', 'out_detY_fast', 'summary');

md = local_build_md(candidates, summary, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5c.1] Li-style relay selection smoke summary ===')
disp(summary)
disp('--- candidate table ---')
disp(struct2table(candidates))
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
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

function candidates = local_build_smoke_candidates()
% Deterministic synthetic candidate bank for ranking validation.

candidates = repmat(struct( ...
    'sat_pair', [], ...
    'pta_len_s', NaN, ...
    'cn_value', NaN, ...
    'detY_rim_value', NaN, ...
    'detY_fast_value', NaN), 4, 1);

candidates(1).sat_pair = [11, 42];
candidates(1).pta_len_s = 52;
candidates(1).cn_value = 28;
candidates(1).detY_rim_value = 1.10e5;
candidates(1).detY_fast_value = 1.06e5;

candidates(2).sat_pair = [18, 76];
candidates(2).pta_len_s = 58;
candidates(2).cn_value = 19;
candidates(2).detY_rim_value = 1.24e5;
candidates(2).detY_fast_value = 1.18e5;

candidates(3).sat_pair = [25, 81];
candidates(3).pta_len_s = 49;
candidates(3).cn_value = 14;
candidates(3).detY_rim_value = 1.17e5;
candidates(3).detY_fast_value = 1.15e5;

candidates(4).sat_pair = [33, 95];
candidates(4).pta_len_s = 55;
candidates(4).cn_value = 24;
candidates(4).detY_rim_value = 1.29e5;
candidates(4).detY_fast_value = 1.30e5;
end

function txt = local_pair_to_text(pair)
txt = sprintf('[%d,%d]', pair(1), pair(2));
end

function md = local_build_md(candidates, summary, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5c.1 Li-style relay selection smoke';
lines{end+1} = '';
lines{end+1} = ['- phase_name = ', char(summary.phase_name)];
lines{end+1} = ['- n_candidates = ', num2str(summary.n_candidates)];
lines{end+1} = ['- best_pta_pair = ', char(summary.best_pta_pair)];
lines{end+1} = ['- best_cn_pair = ', char(summary.best_cn_pair)];
lines{end+1} = ['- best_detY_rim_pair = ', char(summary.best_detY_rim_pair)];
lines{end+1} = ['- best_detY_fast_pair = ', char(summary.best_detY_fast_pair)];
lines{end+1} = '';
lines{end+1} = '## candidates';
for i = 1:numel(candidates)
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
