function out = run_ws5_effect_compare_timescan(scene_preset, k_list)
%RUN_WS5_EFFECT_COMPARE_TIMESCAN
% WS-5-R3
% Multi-step quantification for:
%   A) baseline
%   B) reference_only
%   C) reference_plus_filter
%
% Outputs:
%   outputs/cpt5/ws5_effect_compare_timescan/<scene_preset>/

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k_list)
    k_list = 1:20;
end

cfg0 = default_ch5_params(scene_preset);
caseData = build_ch5_case(cfg0);

out_root = fullfile(pwd, 'outputs', 'cpt5', 'ws5_effect_compare_timescan', scene_preset);
if ~exist(out_root, 'dir'); mkdir(out_root); end

rows_cell = {};
template_family_ref = {};
template_family_filter = {};

for kk = 1:numel(k_list)
    k = k_list(kk);

    visible_ids = find(caseData.candidates.visible_mask(k,:) > 0);
    if numel(visible_ids) < 2
        continue
    end

    pair_sets = nchoosek(visible_ids(:).', 2);
    if isempty(pair_sets)
        continue
    end

    pair_feats = extract_candidate_local_features(caseData, k, pair_sets);
    lib = build_reference_prior_library(pair_feats);

    prev_ids = visible_ids(1:min(2, numel(visible_ids)));

    % A) baseline
    cfgA = cfg0;
    cfgA.ch5.prior_enable = false;
    cfgA.ch5.template_filter_enable = false;
    selected_A = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgA);

    % B) reference_only
    cfgB = cfg0;
    cfgB.ch5.prior_enable = true;
    cfgB.ch5.prior_library = lib;
    cfgB.ch5.template_filter_enable = false;

    query_feat_B = extract_candidate_local_features(caseData, k, visible_ids(:).');
    query_feat_B = query_feat_B(1);
    match_B = match_reference_prior(lib, query_feat_B);
    selected_B = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgB);

    % C) reference_plus_filter
    cfgC = cfg0;
    cfgC.ch5.prior_enable = true;
    cfgC.ch5.prior_library = lib;
    cfgC.ch5.template_filter_enable = true;
    cfgC.ch5.template_filter_topk = min(4, size(pair_sets,1));

    query_feat_C = extract_candidate_local_features(caseData, k, visible_ids(:).');
    query_feat_C = query_feat_C(1);
    match_C = match_reference_prior(lib, query_feat_C);

    cand_feats_C = extract_candidate_local_features(caseData, k, pair_sets);
    filter_C = filter_candidates_by_template(cand_feats_C, lib, match_C, cfgC.ch5.template_filter_topk);
    selected_C = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgC);

    row = struct();
    row.k = k;
    row.visible_count = numel(visible_ids);
    row.num_all_candidates = size(pair_sets,1);
    row.num_kept_candidates = numel(filter_C.keep_idx);
    row.compression_ratio = row.num_kept_candidates / max(row.num_all_candidates, 1);

    row.selected_A = selected_A(:).';
    row.selected_B = selected_B(:).';
    row.selected_C = selected_C(:).';

    row.changed_B_vs_A = ~isequal(row.selected_B, row.selected_A);
    row.changed_C_vs_A = ~isequal(row.selected_C, row.selected_A);
    row.changed_C_vs_B = ~isequal(row.selected_C, row.selected_B);

    row.ref_ids_B = match_B.ref_ids(:).';
    row.ref_ids_C = match_C.ref_ids(:).';

    row.match_family_B = string(match_B.best_template_family);
    row.match_family_C = string(match_C.best_template_family);
    row.match_distance_B = match_B.best_distance;
    row.match_distance_C = match_C.best_distance;

    row.filter_template_family = string(filter_C.template_family);
    row.filter_keep_idx = filter_C.keep_idx(:).';
    row.filter_keep_distances = filter_C.keep_distances(:).';

    rows_cell{end+1} = row; %#ok<AGROW>
    template_family_ref{end+1} = char(row.match_family_B); %#ok<AGROW>
    template_family_filter{end+1} = char(row.filter_template_family); %#ok<AGROW>
end

assert(~isempty(rows_cell), 'No valid k found in the given k_list.');

rows = [rows_cell{:}];

n = numel(rows);
num_changed_B_vs_A = sum([rows.changed_B_vs_A]);
num_changed_C_vs_A = sum([rows.changed_C_vs_A]);
num_changed_C_vs_B = sum([rows.changed_C_vs_B]);

compression = [rows.compression_ratio];
cand_all = [rows.num_all_candidates];
cand_kept = [rows.num_kept_candidates];
dist_B = [rows.match_distance_B];
dist_C = [rows.match_distance_C];

summary = struct();
summary.scene_preset = scene_preset;
summary.k_list = k_list;
summary.num_valid_steps = n;
summary.num_changed_B_vs_A = num_changed_B_vs_A;
summary.num_changed_C_vs_A = num_changed_C_vs_A;
summary.num_changed_C_vs_B = num_changed_C_vs_B;
summary.ratio_changed_B_vs_A = num_changed_B_vs_A / n;
summary.ratio_changed_C_vs_A = num_changed_C_vs_A / n;
summary.ratio_changed_C_vs_B = num_changed_C_vs_B / n;
summary.mean_num_all_candidates = mean(cand_all);
summary.mean_num_kept_candidates = mean(cand_kept);
summary.mean_compression_ratio = mean(compression);
summary.min_compression_ratio = min(compression);
summary.max_compression_ratio = max(compression);
summary.mean_match_distance_B = mean(dist_B);
summary.mean_match_distance_C = mean(dist_C);
summary.template_family_ref = template_family_ref;
summary.template_family_filter = template_family_filter;

txt_path = fullfile(out_root, sprintf('ws5_effect_compare_timescan_%s.txt', scene_preset));
mat_path = fullfile(out_root, sprintf('ws5_effect_compare_timescan_%s.mat', scene_preset));

local_write_txt(txt_path, summary, rows);
save(mat_path, 'summary', 'rows');

out = struct();
out.scene_preset = scene_preset;
out.summary = summary;
out.rows = rows;
out.text_file = txt_path;
out.mat_file = mat_path;

disp('=== WS-5 effect compare timescan ===');
disp(out)
end

function local_write_txt(pathStr, summary, rows)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== WS-5-R3 timescan summary ===\n');
fprintf(fid, 'scene_preset = %s\n', summary.scene_preset);
fprintf(fid, 'num_valid_steps = %d\n', summary.num_valid_steps);
fprintf(fid, 'num_changed_B_vs_A = %d\n', summary.num_changed_B_vs_A);
fprintf(fid, 'num_changed_C_vs_A = %d\n', summary.num_changed_C_vs_A);
fprintf(fid, 'num_changed_C_vs_B = %d\n', summary.num_changed_C_vs_B);
fprintf(fid, 'ratio_changed_B_vs_A = %.6f\n', summary.ratio_changed_B_vs_A);
fprintf(fid, 'ratio_changed_C_vs_A = %.6f\n', summary.ratio_changed_C_vs_A);
fprintf(fid, 'ratio_changed_C_vs_B = %.6f\n', summary.ratio_changed_C_vs_B);
fprintf(fid, 'mean_num_all_candidates = %.6f\n', summary.mean_num_all_candidates);
fprintf(fid, 'mean_num_kept_candidates = %.6f\n', summary.mean_num_kept_candidates);
fprintf(fid, 'mean_compression_ratio = %.6f\n', summary.mean_compression_ratio);
fprintf(fid, 'min_compression_ratio = %.6f\n', summary.min_compression_ratio);
fprintf(fid, 'max_compression_ratio = %.6f\n', summary.max_compression_ratio);
fprintf(fid, 'mean_match_distance_B = %.6f\n', summary.mean_match_distance_B);
fprintf(fid, 'mean_match_distance_C = %.6f\n', summary.mean_match_distance_C);
fprintf(fid, '\n');

for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '--- k = %d ---\n', r.k);
    fprintf(fid, 'visible_count = %d\n', r.visible_count);
    fprintf(fid, 'num_all_candidates = %d\n', r.num_all_candidates);
    fprintf(fid, 'num_kept_candidates = %d\n', r.num_kept_candidates);
    fprintf(fid, 'compression_ratio = %.6f\n', r.compression_ratio);
    fprintf(fid, 'selected_A = %s\n', local_vec_to_str(r.selected_A));
    fprintf(fid, 'selected_B = %s\n', local_vec_to_str(r.selected_B));
    fprintf(fid, 'selected_C = %s\n', local_vec_to_str(r.selected_C));
    fprintf(fid, 'changed_B_vs_A = %d\n', r.changed_B_vs_A);
    fprintf(fid, 'changed_C_vs_A = %d\n', r.changed_C_vs_A);
    fprintf(fid, 'changed_C_vs_B = %d\n', r.changed_C_vs_B);
    fprintf(fid, 'ref_ids_B = %s\n', local_vec_to_str(r.ref_ids_B));
    fprintf(fid, 'ref_ids_C = %s\n', local_vec_to_str(r.ref_ids_C));
    fprintf(fid, 'match_family_B = %s\n', char(r.match_family_B));
    fprintf(fid, 'match_family_C = %s\n', char(r.match_family_C));
    fprintf(fid, 'match_distance_B = %.6f\n', r.match_distance_B);
    fprintf(fid, 'match_distance_C = %.6f\n', r.match_distance_C);
    fprintf(fid, 'filter_template_family = %s\n', char(r.filter_template_family));
    fprintf(fid, 'filter_keep_idx = %s\n', local_vec_to_str(r.filter_keep_idx));
    fprintf(fid, 'filter_keep_distances = %s\n', local_vec_to_str(r.filter_keep_distances));
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
