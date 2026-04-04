function pair_list_pruned = prune_candidate_pairs_with_weak_prior(cfg, prior, pair_list)
%PRUNE_CANDIDATE_PAIRS_WITH_WEAK_PRIOR
% Candidate pruning with weak prior.
%
% Current minimal rule:
% - rank by weak prior score
% - keep top ceil(keep_ratio * nPairs), but at least min_keep pairs

if nargin < 3
    error('cfg, prior, pair_list are required.');
end

if isempty(pair_list)
    pair_list_pruned = pair_list;
    return;
end

if ~isfield(cfg.ch5r.r8, 'enable_candidate_prune') || ~cfg.ch5r.r8.enable_candidate_prune
    pair_list_pruned = pair_list;
    return;
end

keep_ratio = cfg.ch5r.r8.prune_keep_ratio;
min_keep = cfg.ch5r.r8.prune_min_keep;

nPairs = size(pair_list, 1);
keep_n = max(min_keep, ceil(keep_ratio * nPairs));
keep_n = min(keep_n, nPairs);

scores = zeros(nPairs,1);
for i = 1:nPairs
    scores(i) = score_tiebreak_with_static_prior(prior, pair_list(i,:));
end

[~, idx] = sort(scores, 'descend');
pair_list_pruned = pair_list(idx(1:keep_n), :);
end
