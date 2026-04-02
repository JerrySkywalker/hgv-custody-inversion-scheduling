function out = run_ws4_reference_selection_smoke(scene_preset, k)
%RUN_WS4_REFERENCE_SELECTION_SMOKE
% WS-4-R1
% Build a small template library and test template-guided reference selection.

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
multi_feat = extract_candidate_local_features(caseData, k, visible_ids(:).');
all_feats = [pair_feats, multi_feat];

lib = build_reference_prior_library(all_feats);

cfg.ch5.prior_enable = true;
cfg.ch5.prior_library = lib;

query_feat = multi_feat(1);
match = match_reference_prior(lib, query_feat);
ref_ids = match.ref_ids;

if numel(visible_ids) >= 3
    prev_ids = visible_ids(1:2);
else
    prev_ids = [];
end

selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, 'warn', cfg);

out = struct();
out.scene_preset = scene_preset;
out.k = k;
out.visible_ids = visible_ids;
out.library = lib;
out.query_feat = query_feat;
out.match = match;
out.ref_ids = ref_ids;
out.selected_ids = selected_ids;

disp('=== WS-4 reference-selection smoke ===');
disp(out)
end
