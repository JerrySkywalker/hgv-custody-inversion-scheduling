function best_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALOOP
% NX-4 second round
% Baseline selection + soft proposal tie-break.
%
% This version keeps the main CK chain intact and only applies
% a small proposal-based bonus in warn/trigger modes.

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

scores = nan(size(cand_sets,1),1);

for i = 1:size(cand_sets,1)
    ids = cand_sets(i,:);
    [s_base, ~] = build_window_objective_dualloop(mode, ids, prev_ids, [], caseData, k, cfg);

    if use_soft
        [soft_bonus, ~] = score_nx4_soft_proposal_bonus(ids, proposal_pairs, proposal_scores, cfg);
        scores(i) = s_base - soft_bonus;
    else
        scores(i) = s_base;
    end
end

[~, idx] = min(scores);
best_ids = cand_sets(idx,:);
end
