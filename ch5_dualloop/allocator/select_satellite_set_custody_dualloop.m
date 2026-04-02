function best_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALOOP
% NX-4 patched soft proposal tie-break
%
% Main rule:
%   1) compute baseline scores for all candidate pairs
%   2) keep only a small frontier near the best baseline score
%   3) apply proposal tie-break only inside that frontier

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

cfg = apply_nx4_proposal_defaults(cfg);
cfg = apply_nx4_soft_defaults(cfg);

visible_ids = find(caseData.candidates.visible_mask(k,:) > 0);

if isempty(visible_ids)
    best_ids = [];
    return
end

if numel(visible_ids) < 2
    best_ids = visible_ids(:).';
    return
end

cand_sets = nchoosek(visible_ids, 2);
nCand = size(cand_sets,1);

use_soft = cfg.ch5.nx4_soft_enable && any(strcmpi(char(mode), {'warn','trigger'}));

proposal_pairs = [];
proposal_scores = [];
if use_soft
    try
        P = build_nx4_template_proposal(caseData, k, cfg);
        proposal_pairs = P.proposal_pairs;
        proposal_scores = P.proposal_scores;
    catch
        proposal_pairs = [];
        proposal_scores = [];
    end
end

base_scores = nan(nCand,1);
for i = 1:nCand
    ids = cand_sets(i,:);
    [s_base, ~] = build_window_objective_dualloop(mode, ids, prev_ids, [], caseData, k, cfg);
    base_scores(i) = s_base;
end

[sorted_base, ord_base] = sort(base_scores, 'ascend');
best_base = sorted_base(1);

frontier_m = min(cfg.ch5.nx4_soft_frontier_m, nCand);
margin = cfg.ch5.nx4_soft_score_margin;

frontier_mask = false(nCand,1);
for j = 1:frontier_m
    idx = ord_base(j);
    if (base_scores(idx) - best_base) <= margin
        frontier_mask(idx) = true;
    end
end

final_scores = base_scores;

if use_soft && any(frontier_mask)
    for i = 1:nCand
        if frontier_mask(i)
            ids = cand_sets(i,:);
            [soft_bonus, ~] = score_nx4_soft_proposal_bonus(ids, proposal_pairs, proposal_scores, cfg);
            final_scores(i) = base_scores(i) - soft_bonus;
        end
    end
end

[~, idx] = min(final_scores);
best_ids = cand_sets(idx,:);
end
