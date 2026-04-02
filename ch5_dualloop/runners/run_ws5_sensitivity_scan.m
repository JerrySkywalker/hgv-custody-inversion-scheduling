function out = run_ws5_sensitivity_scan(scene_preset, k_list, topk_grid, libcap_grid)
%RUN_WS5_SENSITIVITY_SCAN
% WS-5-R4
% Scan topK x library_pair_cap and export text + figures.

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k_list)
    k_list = 1:20;
end
if nargin < 3 || isempty(topk_grid)
    topk_grid = [2 4 6 8];
end
if nargin < 4 || isempty(libcap_grid)
    libcap_grid = [5 10 20];
end

cfg0 = default_ch5_params(scene_preset);
caseData = build_ch5_case(cfg0);

out_root = fullfile(pwd, 'outputs', 'cpt5', 'ws5_sensitivity_scan', scene_preset);
fig_dir = fullfile(out_root, 'figs');
if ~exist(out_root, 'dir'); mkdir(out_root); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

nt = numel(topk_grid);
nl = numel(libcap_grid);

ratio_changed_B_vs_A = nan(nt, nl);
ratio_changed_C_vs_A = nan(nt, nl);
ratio_changed_C_vs_B = nan(nt, nl);
mean_num_all_candidates = nan(nt, nl);
mean_num_kept_candidates = nan(nt, nl);
mean_compression_ratio = nan(nt, nl);
mean_match_distance_B = nan(nt, nl);
mean_match_distance_C = nan(nt, nl);

records_cell = cell(nt, nl);

for it = 1:nt
    for il = 1:nl
        topK = topk_grid(it);
        pair_cap = libcap_grid(il);

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

            pair_sets = pair_sets(1:min(pair_cap, size(pair_sets,1)), :);
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
            cfgC.ch5.template_filter_topk = min(topK, size(pair_sets,1));

            query_feat_C = extract_candidate_local_features(caseData, k, visible_ids(:).');
            query_feat_C = query_feat_C(1);
            match_C = match_reference_prior(lib, query_feat_C);

            cand_feats_C = extract_candidate_local_features(caseData, k, pair_sets);
            filter_C = filter_candidates_by_template(cand_feats_C, lib, match_C, cfgC.ch5.template_filter_topk);

            selected_C = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfgC);

            row = struct();
            row.k = k;
            row.visible_count = numel(visible_ids);
            row.topK = cfgC.ch5.template_filter_topk;
            row.library_pair_cap = pair_cap;
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
        end

        assert(~isempty(rows_cell), 'No valid rows for topK=%d, pair_cap=%d.', topK, pair_cap);
        rows = [rows_cell{:}];
        records_cell{it, il} = rows;

        n = numel(rows);
        ratio_changed_B_vs_A(it, il) = sum([rows.changed_B_vs_A]) / n;
        ratio_changed_C_vs_A(it, il) = sum([rows.changed_C_vs_A]) / n;
        ratio_changed_C_vs_B(it, il) = sum([rows.changed_C_vs_B]) / n;
        mean_num_all_candidates(it, il) = mean([rows.num_all_candidates]);
        mean_num_kept_candidates(it, il) = mean([rows.num_kept_candidates]);
        mean_compression_ratio(it, il) = mean([rows.compression_ratio]);
        mean_match_distance_B(it, il) = mean([rows.match_distance_B]);
        mean_match_distance_C(it, il) = mean([rows.match_distance_C]);
    end
end

summary = struct();
summary.scene_preset = scene_preset;
summary.k_list = k_list;
summary.topk_grid = topk_grid;
summary.libcap_grid = libcap_grid;
summary.ratio_changed_B_vs_A = ratio_changed_B_vs_A;
summary.ratio_changed_C_vs_A = ratio_changed_C_vs_A;
summary.ratio_changed_C_vs_B = ratio_changed_C_vs_B;
summary.mean_num_all_candidates = mean_num_all_candidates;
summary.mean_num_kept_candidates = mean_num_kept_candidates;
summary.mean_compression_ratio = mean_compression_ratio;
summary.mean_match_distance_B = mean_match_distance_B;
summary.mean_match_distance_C = mean_match_distance_C;

txt_path = fullfile(out_root, sprintf('ws5_sensitivity_scan_%s.txt', scene_preset));
mat_path = fullfile(out_root, sprintf('ws5_sensitivity_scan_%s.mat', scene_preset));

local_write_txt(txt_path, summary);
save(mat_path, 'summary', 'records_cell');

figs = plot_ws5_sensitivity_results(summary, fig_dir);

out = struct();
out.scene_preset = scene_preset;
out.summary = summary;
out.records_cell = records_cell;
out.text_file = txt_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
out.fig_files = figs;

disp('=== WS-5 sensitivity scan ===');
disp(out)
end

function local_write_txt(pathStr, S)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== WS-5-R4 sensitivity scan summary ===\n');
fprintf(fid, 'scene_preset = %s\n', S.scene_preset);
fprintf(fid, 'topk_grid = %s\n', local_vec_to_str(S.topk_grid));
fprintf(fid, 'libcap_grid = %s\n', local_vec_to_str(S.libcap_grid));
fprintf(fid, '\n');

fprintf(fid, '--- ratio_changed_B_vs_A ---\n');
local_write_matrix(fid, S.ratio_changed_B_vs_A);

fprintf(fid, '\n--- ratio_changed_C_vs_A ---\n');
local_write_matrix(fid, S.ratio_changed_C_vs_A);

fprintf(fid, '\n--- ratio_changed_C_vs_B ---\n');
local_write_matrix(fid, S.ratio_changed_C_vs_B);

fprintf(fid, '\n--- mean_num_all_candidates ---\n');
local_write_matrix(fid, S.mean_num_all_candidates);

fprintf(fid, '\n--- mean_num_kept_candidates ---\n');
local_write_matrix(fid, S.mean_num_kept_candidates);

fprintf(fid, '\n--- mean_compression_ratio ---\n');
local_write_matrix(fid, S.mean_compression_ratio);

fprintf(fid, '\n--- mean_match_distance_B ---\n');
local_write_matrix(fid, S.mean_match_distance_B);

fprintf(fid, '\n--- mean_match_distance_C ---\n');
local_write_matrix(fid, S.mean_match_distance_C);
end

function local_write_matrix(fid, M)
for i = 1:size(M,1)
    fprintf(fid, '%s\n', local_vec_to_str(M(i,:)));
end
end

function s = local_vec_to_str(v)
if isempty(v)
    s = '[]';
    return
end
v = v(:).';
parts = arrayfun(@(x) num2str(x, '%.6g'), v, 'UniformOutput', false);
s = ['[', strjoin(parts, ' '), ']'];
end
