function out = run_ws5_parameter_finalize_export(scene_preset, k_list)
%RUN_WS5_PARAMETER_FINALIZE_EXPORT
% WS-5-R5
% Finalize recommended parameter sets and export publication-style text + plots.
%
% Fixed profiles:
%   aggressive   : topK=2, cap=5
%   balanced     : topK=4, cap=10
%   conservative : topK=8, cap=20

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k_list)
    k_list = 1:20;
end

cfg0 = default_ch5_params(scene_preset);
caseData = build_ch5_case(cfg0);

profiles = struct( ...
    'name', {'aggressive','balanced','conservative'}, ...
    'topK', {2,4,8}, ...
    'cap',  {5,10,20});

out_root = fullfile(pwd, 'outputs', 'cpt5', 'ws5_parameter_finalize', scene_preset);
fig_dir = fullfile(out_root, 'figs');
if ~exist(out_root, 'dir'); mkdir(out_root); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

records_cell = cell(1, numel(profiles));

for ip = 1:numel(profiles)
    P = profiles(ip);
    rows_cell = {};

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

        pair_sets = pair_sets(1:min(P.cap, size(pair_sets,1)), :);
        pair_feats = extract_candidate_local_features(caseData, k, pair_sets);
        lib = build_reference_prior_library(pair_feats);

        prev_ids = visible_ids(1:min(2, numel(visible_ids)));

        % baseline
        cfgA = cfg0;
        cfgA.ch5.prior_enable = false;
        cfgA.ch5.template_filter_enable = false;
        selected_A = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgA);

        % reference_only
        cfgB = cfg0;
        cfgB.ch5.prior_enable = true;
        cfgB.ch5.prior_library = lib;
        cfgB.ch5.template_filter_enable = false;

        query_feat_B = extract_candidate_local_features(caseData, k, visible_ids(:).');
        query_feat_B = query_feat_B(1);
        match_B = match_reference_prior(lib, query_feat_B);
        selected_B = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgB);

        % reference_plus_filter
        cfgC = cfg0;
        cfgC.ch5.prior_enable = true;
        cfgC.ch5.prior_library = lib;
        cfgC.ch5.template_filter_enable = true;
        cfgC.ch5.template_filter_topk = min(P.topK, size(pair_sets,1));

        query_feat_C = extract_candidate_local_features(caseData, k, visible_ids(:).');
        query_feat_C = query_feat_C(1);
        match_C = match_reference_prior(lib, query_feat_C);

        cand_feats_C = extract_candidate_local_features(caseData, k, pair_sets);
        filter_C = filter_candidates_by_template(cand_feats_C, lib, match_C, cfgC.ch5.template_filter_topk);
        selected_C = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgC);

        row = struct();
        row.profile_name = string(P.name);
        row.k = k;
        row.topK = P.topK;
        row.library_pair_cap = P.cap;
        row.visible_count = numel(visible_ids);
        row.num_all_candidates = size(pair_sets,1);
        row.num_kept_candidates = numel(filter_C.keep_idx);
        row.compression_ratio = row.num_kept_candidates / max(row.num_all_candidates,1);

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
    end

    assert(~isempty(rows_cell), 'No valid rows for profile %s.', P.name);
    records_cell{ip} = [rows_cell{:}];
end

profiles_summary_cell = cell(1, numel(profiles));
for ip = 1:numel(profiles)
    rows = records_cell{ip};
    S = struct();
    S.profile_name = profiles(ip).name;
    S.topK = profiles(ip).topK;
    S.library_pair_cap = profiles(ip).cap;
    S.num_valid_steps = numel(rows);
    S.ratio_changed_B_vs_A = sum([rows.changed_B_vs_A]) / numel(rows);
    S.ratio_changed_C_vs_A = sum([rows.changed_C_vs_A]) / numel(rows);
    S.ratio_changed_C_vs_B = sum([rows.changed_C_vs_B]) / numel(rows);
    S.mean_num_all_candidates = mean([rows.num_all_candidates]);
    S.mean_num_kept_candidates = mean([rows.num_kept_candidates]);
    S.mean_compression_ratio = mean([rows.compression_ratio]);
    S.mean_match_distance_B = mean([rows.match_distance_B]);
    S.mean_match_distance_C = mean([rows.match_distance_C]);
    profiles_summary_cell{ip} = S;
end
profiles_summary = [profiles_summary_cell{:}];

recommendation = local_build_recommendation(scene_preset, profiles_summary);

txt_path = fullfile(out_root, sprintf('ws5_parameter_finalize_%s.txt', scene_preset));
mat_path = fullfile(out_root, sprintf('ws5_parameter_finalize_%s.mat', scene_preset));

local_write_txt(txt_path, scene_preset, k_list, profiles_summary, recommendation);
save(mat_path, 'profiles_summary', 'records_cell', 'recommendation');

figs = plot_ws5_publication_style(scene_preset, profiles_summary, fig_dir);

out = struct();
out.scene_preset = scene_preset;
out.k_list = k_list;
out.profiles_summary = profiles_summary;
out.recommendation = recommendation;
out.text_file = txt_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
out.fig_files = figs;

disp('=== WS-5 parameter finalize export ===');
disp(out)
end

function rec = local_build_recommendation(scene_preset, S)
rec = struct();
rec.scene_preset = scene_preset;

switch lower(scene_preset)
    case 'ref128'
        target_name = 'balanced';
        reason = 'strong decision-change scene; balanced setting keeps full decision-change while avoiding overly aggressive pruning.';
    case 'stress96'
        target_name = 'balanced';
        reason = 'sensitivity scene; balanced setting preserves search-space compression while avoiding over-aggressive decision forcing.';
    otherwise
        target_name = 'balanced';
        reason = 'default balanced setting.';
end

idx = find(strcmp({S.profile_name}, target_name), 1, 'first');
assert(~isempty(idx), 'Recommended profile not found.');

rec.recommended_profile = S(idx).profile_name;
rec.topK = S(idx).topK;
rec.library_pair_cap = S(idx).library_pair_cap;
rec.reason = reason;
end

function local_write_txt(pathStr, scene_preset, k_list, S, rec)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== WS-5-R5 parameter finalize ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);
fprintf(fid, 'k_list = %s\n\n', local_vec_to_str(k_list));

for i = 1:numel(S)
    x = S(i);
    fprintf(fid, '--- %s ---\n', x.profile_name);
    fprintf(fid, 'topK = %d\n', x.topK);
    fprintf(fid, 'library_pair_cap = %d\n', x.library_pair_cap);
    fprintf(fid, 'num_valid_steps = %d\n', x.num_valid_steps);
    fprintf(fid, 'ratio_changed_B_vs_A = %.6f\n', x.ratio_changed_B_vs_A);
    fprintf(fid, 'ratio_changed_C_vs_A = %.6f\n', x.ratio_changed_C_vs_A);
    fprintf(fid, 'ratio_changed_C_vs_B = %.6f\n', x.ratio_changed_C_vs_B);
    fprintf(fid, 'mean_num_all_candidates = %.6f\n', x.mean_num_all_candidates);
    fprintf(fid, 'mean_num_kept_candidates = %.6f\n', x.mean_num_kept_candidates);
    fprintf(fid, 'mean_compression_ratio = %.6f\n', x.mean_compression_ratio);
    fprintf(fid, 'mean_match_distance_B = %.6f\n', x.mean_match_distance_B);
    fprintf(fid, 'mean_match_distance_C = %.6f\n\n', x.mean_match_distance_C);
end

fprintf(fid, '=== recommendation ===\n');
fprintf(fid, 'recommended_profile = %s\n', rec.recommended_profile);
fprintf(fid, 'topK = %d\n', rec.topK);
fprintf(fid, 'library_pair_cap = %d\n', rec.library_pair_cap);
fprintf(fid, 'reason = %s\n', rec.reason);
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
