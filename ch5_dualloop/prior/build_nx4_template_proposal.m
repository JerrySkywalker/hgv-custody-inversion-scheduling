function out = build_nx4_template_proposal(caseData, k, cfg)
%BUILD_NX4_TEMPLATE_PROPOSAL
% NX-4 first round
% Build a standalone proposal layer from template library + local geometry.
%
% No hard filtering. No modification of main selection chain.

cfg = apply_nx4_proposal_defaults(cfg);

ref_k = cfg.ch5.nx4_reference_k;
ref_k = max(1, min(ref_k, numel(caseData.candidates.sets)));

ref_visible_ids = find(caseData.candidates.visible_mask(ref_k,:) > 0);
cur_visible_ids = find(caseData.candidates.visible_mask(k,:) > 0);

assert(~isempty(ref_visible_ids), 'No visible ids at reference snapshot.');
assert(~isempty(cur_visible_ids), 'No visible ids at current snapshot.');

ref_pair_sets = local_build_pair_sets(ref_visible_ids, cfg.ch5.nx4_library_pair_cap);
cur_pair_sets = local_build_pair_sets(cur_visible_ids, cfg.ch5.nx4_current_pair_cap);

ref_pair_feats = extract_candidate_local_features(caseData, ref_k, ref_pair_sets);
ref_multi_feat = extract_candidate_local_features(caseData, ref_k, ref_visible_ids);
if numel(ref_multi_feat) > 1
    ref_multi_feat = ref_multi_feat(1);
end

library_feats = [ref_pair_feats ref_multi_feat];
library = build_reference_prior_library(library_feats);

cur_pair_feats = extract_candidate_local_features(caseData, k, cur_pair_sets);
query_feat = extract_candidate_local_features(caseData, k, cur_visible_ids);
if numel(query_feat) > 1
    query_feat = query_feat(1);
end

match = match_reference_prior(library, query_feat);
prototype = library.templates(match.best_index).prototype_feature;

scores = nan(1, numel(cur_pair_feats));
for i = 1:numel(cur_pair_feats)
    scores(i) = local_feature_distance(cur_pair_feats(i), prototype);
end

[sorted_scores, ord] = sort(scores, 'ascend');
topk = min(cfg.ch5.nx4_topk, numel(ord));

proposal_pairs = cur_pair_sets(ord(1:topk), :);
proposal_scores = sorted_scores(1:topk);

out = struct();
out.k = k;
out.reference_k = ref_k;
out.reference_visible_ids = ref_visible_ids;
out.current_visible_ids = cur_visible_ids;
out.library = library;
out.query_feat = query_feat;
out.match = match;
out.proposal_pairs = proposal_pairs;
out.proposal_scores = proposal_scores;
out.current_pair_sets = cur_pair_sets;
out.current_pair_scores = scores;
end

function pair_sets = local_build_pair_sets(visible_ids, cap_n)
visible_ids = visible_ids(:).';
if numel(visible_ids) < 2
    pair_sets = visible_ids;
    return
end

pair_sets = nchoosek(visible_ids, 2);
if nargin >= 2 && ~isempty(cap_n) && size(pair_sets,1) > cap_n
    pair_sets = pair_sets(1:cap_n, :);
end
end

function d = local_feature_distance(a, b)
v = [
    local_get_num(a, 'baseline_km') - local_get_num(b, 'baseline_km'), ...
    local_get_num(a, 'Bxy_cand')    - local_get_num(b, 'Bxy_cand'), ...
    local_get_num(a, 'Ruse')        - local_get_num(b, 'Ruse'), ...
    local_get_num(a, 'num_sats')    - local_get_num(b, 'num_sats')];
d = norm(v, 2);
end

function x = local_get_num(s, field_name)
x = 0;
if isstruct(s) && isfield(s, field_name)
    v = s.(field_name);
    if isnumeric(v) && isscalar(v) && isfinite(v)
        x = double(v);
    end
end
end
