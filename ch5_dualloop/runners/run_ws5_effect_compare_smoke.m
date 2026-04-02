function out = run_ws5_effect_compare_smoke(scene_preset, k)
%RUN_WS5_EFFECT_COMPARE_SMOKE
% WS-5-R2
% Quantify and export the effect of:
%   A) baseline (no prior, no filter)
%   B) WS-4 reference selection only
%   C) WS-5 reference selection + template filtering
%
% Output:
%   outputs/cpt5/ws5_effect_compare/<scene_preset>/

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k)
    k = 10;
end

cfg0 = default_ch5_params(scene_preset);
caseData = build_ch5_case(cfg0);

out_root = fullfile(pwd, 'outputs', 'cpt5', 'ws5_effect_compare', scene_preset);
if ~exist(out_root, 'dir'); mkdir(out_root); end

visible_ids = find(caseData.candidates.visible_mask(k,:) > 0);
assert(numel(visible_ids) >= 2, 'Need at least 2 visible satellites.');

pair_sets = nchoosek(visible_ids(:).', 2);
pair_sets = pair_sets(1:min(10, size(pair_sets,1)), :);
pair_feats = extract_candidate_local_features(caseData, k, pair_sets);

lib = build_reference_prior_library(pair_feats);

prev_ids = visible_ids(1:min(2, numel(visible_ids)));

% ------------------------------------------------
% A) Baseline
% ------------------------------------------------
cfgA = cfg0;
cfgA.ch5.prior_enable = false;
cfgA.ch5.template_filter_enable = false;

selected_A = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgA);

recA = struct();
recA.mode_name = 'baseline';
recA.visible_ids = visible_ids(:).';
recA.selected_ids = selected_A;
recA.ref_ids = [];
recA.match = [];
recA.filter = [];
recA.num_all_candidates = size(pair_sets, 1);
recA.num_kept_candidates = size(pair_sets, 1);

% ------------------------------------------------
% B) WS-4 reference selection only
% ------------------------------------------------
cfgB = cfg0;
cfgB.ch5.prior_enable = true;
cfgB.ch5.prior_library = lib;
cfgB.ch5.template_filter_enable = false;

query_feat_B = extract_candidate_local_features(caseData, k, visible_ids(:).');
query_feat_B = query_feat_B(1);
match_B = match_reference_prior(lib, query_feat_B);
selected_B = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgB);

recB = struct();
recB.mode_name = 'reference_only';
recB.visible_ids = visible_ids(:).';
recB.selected_ids = selected_B;
recB.ref_ids = match_B.ref_ids(:).';
recB.match = match_B;
recB.filter = [];
recB.num_all_candidates = size(pair_sets, 1);
recB.num_kept_candidates = size(pair_sets, 1);

% ------------------------------------------------
% C) WS-5 reference + filtering
% ------------------------------------------------
cfgC = cfg0;
cfgC.ch5.prior_enable = true;
cfgC.ch5.prior_library = lib;
cfgC.ch5.template_filter_enable = true;
cfgC.ch5.template_filter_topk = 4;

query_feat_C = extract_candidate_local_features(caseData, k, visible_ids(:).');
query_feat_C = query_feat_C(1);
match_C = match_reference_prior(lib, query_feat_C);

cand_feats_C = extract_candidate_local_features(caseData, k, pair_sets);
filter_C = filter_candidates_by_template(cand_feats_C, lib, match_C, cfgC.ch5.template_filter_topk);

selected_C = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgC);

recC = struct();
recC.mode_name = 'reference_plus_filter';
recC.visible_ids = visible_ids(:).';
recC.selected_ids = selected_C;
recC.ref_ids = match_C.ref_ids(:).';
recC.match = match_C;
recC.filter = filter_C;
recC.num_all_candidates = size(pair_sets, 1);
recC.num_kept_candidates = numel(filter_C.keep_idx);

records = [recA, recB, recC];

txt_path = fullfile(out_root, sprintf('ws5_effect_compare_%s_k%04d.txt', scene_preset, k));
mat_path = fullfile(out_root, sprintf('ws5_effect_compare_%s_k%04d.mat', scene_preset, k));

local_write_txt(txt_path, records, scene_preset, k);
save(mat_path, 'records', 'scene_preset', 'k', 'visible_ids', 'pair_sets');

out = struct();
out.scene_preset = scene_preset;
out.k = k;
out.visible_ids = visible_ids;
out.records = records;
out.text_file = txt_path;
out.mat_file = mat_path;

disp('=== WS-5 effect compare smoke ===');
disp(out)
end

function local_write_txt(pathStr, records, scene_preset, k)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== WS-5-R2 effect compare ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);
fprintf(fid, 'k = %d\n\n', k);

for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '--- %s ---\n', r.mode_name);
    fprintf(fid, 'visible_ids = %s\n', local_vec_to_str(r.visible_ids));
    fprintf(fid, 'selected_ids = %s\n', local_vec_to_str(r.selected_ids));
    fprintf(fid, 'ref_ids = %s\n', local_vec_to_str(r.ref_ids));
    fprintf(fid, 'num_all_candidates = %d\n', r.num_all_candidates);
    fprintf(fid, 'num_kept_candidates = %d\n', r.num_kept_candidates);

    if ~isempty(r.match)
        fprintf(fid, 'match.best_template_id = %s\n', r.match.best_template_id);
        fprintf(fid, 'match.best_template_family = %s\n', r.match.best_template_family);
        fprintf(fid, 'match.best_distance = %.6f\n', r.match.best_distance);
        fprintf(fid, 'match.ref_ids = %s\n', local_vec_to_str(r.match.ref_ids));
    end

    if ~isempty(r.filter)
        fprintf(fid, 'filter.keep_idx = %s\n', local_vec_to_str(r.filter.keep_idx));
        fprintf(fid, 'filter.keep_distances = %s\n', local_vec_to_str(r.filter.keep_distances.'));
        fprintf(fid, 'filter.template_id = %s\n', r.filter.template_id);
        fprintf(fid, 'filter.template_family = %s\n', r.filter.template_family);
    end
    fprintf(fid, '\n');
end
end

function s = local_vec_to_str(v)
if isempty(v)
    s = '[]';
    return
end
v = v(:).';
parts = arrayfun(@num2str, v, 'UniformOutput', false);
s = ['[', strjoin(parts, ' '), ']'];
end
