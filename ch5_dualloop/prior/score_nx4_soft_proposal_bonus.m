function [soft_bonus, info] = score_nx4_soft_proposal_bonus(candidate_ids, proposal_pairs, proposal_scores, cfg)
%SCORE_NX4_SOFT_PROPOSAL_BONUS
% NX-4 patched
% Stronger soft bonus for proposal top-k candidates.

cfg = apply_nx4_soft_defaults(cfg);

soft_bonus = 0.0;
info = struct();
info.hit = false;
info.rank = NaN;
info.is_in_topk = false;

if isempty(proposal_pairs)
    return
end

cand = sort(candidate_ids(:).');
topk = min(cfg.ch5.nx4_soft_topk, size(proposal_pairs,1));
pairs_topk = proposal_pairs(1:topk, :);

for i = 1:size(pairs_topk,1)
    p = sort(pairs_topk(i,:));
    if isequal(cand, p)
        info.hit = true;
        info.is_in_topk = true;
        info.rank = i;
        soft_bonus = cfg.ch5.nx4_soft_bonus_weight / i;
        return
    end
end
end
