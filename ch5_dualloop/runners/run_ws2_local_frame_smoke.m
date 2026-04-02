function out = run_ws2_local_frame_smoke(scene_preset, k)
%RUN_WS2_LOCAL_FRAME_SMOKE
% WS-2-R1 smoke:
% 1) single visible 2-sat set
% 2) one visible-all set
% 3) first few 2-combinations from visible ids

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

pair_ids = visible_ids(1:2);
geom_pair = extract_local_frame_geometry(caseData, k, pair_ids);

all_ids = visible_ids(:).';
geom_all = extract_local_frame_geometry(caseData, k, all_ids);

pair_sets = nchoosek(visible_ids(:).', 2);
pair_sets = pair_sets(1:min(5, size(pair_sets,1)), :);
feats_pairs = extract_candidate_local_features(caseData, k, pair_sets);

out = struct();
out.scene_preset = scene_preset;
out.k = k;
out.visible_ids = visible_ids;
out.geom_pair = geom_pair;
out.geom_all = geom_all;
out.feats_pairs = feats_pairs;

disp('=== WS-2 local-frame smoke ===');
disp(out)
end
