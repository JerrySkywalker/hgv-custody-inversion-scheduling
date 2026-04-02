function [soft_bonus, info] = score_nx4_soft_proposal_bonus(candidate_ids, proposal_pairs, proposal_scores, cfg)
%SCORE_NX4_SOFT_PROPOSAL_BONUS
% NX-4 second round
% Small bonus for candidates that appear in proposal top-k.
%
% Larger bonus for higher-ranked proposal entries.

cfg = apply_nx4_soft_defaults(cfg);

soft_bonus = 0.0;
info = struct();
info.hit = false;
info.rank = NaN;

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
        info.rank = i;
        soft_bonus = cfg.ch5.nx4_soft_bonus_weight / i;
        return
    end
end
end
