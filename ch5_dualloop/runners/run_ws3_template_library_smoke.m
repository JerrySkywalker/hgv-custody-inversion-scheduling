function out = run_ws3_template_library_smoke(scene_preset, k)
%RUN_WS3_TEMPLATE_LIBRARY_SMOKE
% WS-3-R1
% Build a small prototype library from visible candidates and test matching.

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

multi_set = visible_ids(:).';

pair_feats = extract_candidate_local_features(caseData, k, pair_sets);
multi_feat = extract_candidate_local_features(caseData, k, multi_set);

all_feats = [pair_feats, multi_feat];
lib = build_reference_prior_library(all_feats);

query = pair_feats(1);
match = match_reference_prior(query, lib);

out = struct();
out.scene_preset = scene_preset;
out.k = k;
out.visible_ids = visible_ids;
out.pair_feats = pair_feats;
out.multi_feat = multi_feat;
out.library = lib;
out.query = query;
out.match = match;

disp('=== WS-3 template-library smoke ===');
disp(out)
end
