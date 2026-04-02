function out = run_ws5_candidate_filter_smoke(scene_preset, k)
%RUN_WS5_CANDIDATE_FILTER_SMOKE
% WS-5-R1
% Build pair-only template library, enable template-guided reference selection
% and candidate filtering, then run one warn-mode selection.

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k)
    k = 10;
end

cfg = default_ch5_params(scene_preset);
caseData = build_ch5_case(cfg);

visible_ids = find(caseData.candidates.visible_mask(k,:) > 0);
assert(numel(visible_ids) >= 2, 'Need at least 2 visible satellites.');

pair_sets = nchoosek(visible_ids(:).', 2);
pair_sets = pair_sets(1:min(10, size(pair_sets,1)), :);

pair_feats = extract_candidate_local_features(caseData, k, pair_sets);
lib = build_reference_prior_library(pair_feats);

cfg.ch5.prior_enable = true;
cfg.ch5.prior_library = lib;
cfg.ch5.template_filter_enable = true;
cfg.ch5.template_filter_topk = 4;

query_feat = extract_candidate_local_features(caseData, k, visible_ids(:).');
query_feat = query_feat(1);
match = match_reference_prior(lib, query_feat);

cand_feats = extract_candidate_local_features(caseData, k, pair_sets);
filt = filter_candidates_by_template(cand_feats, lib, match, cfg.ch5.template_filter_topk);

prev_ids = visible_ids(1:min(2, numel(visible_ids)));
selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfg);

out = struct();
out.scene_preset = scene_preset;
out.k = k;
out.visible_ids = visible_ids;
out.library = lib;
out.match = match;
out.filter = filt;
out.selected_ids = selected_ids;

disp('=== WS-5 candidate-filter smoke ===');
disp(out)
end
