function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, prior_map, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP  Dual-loop custody selection with outer prior bonus.

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

max_track_sats = cfg.ch5.max_track_sats;
prior_weight = cfg.ch5.outer_prior_weight;

visible_ids = caseData.candidates.sets{k};
visible_ids = visible_ids(:).';

if isempty(visible_ids)
    selected_ids = [];
    return;
end

m = min(max_track_sats, numel(visible_ids));
if numel(visible_ids) == m
    selected_ids = visible_ids;
    return;
end

best_score = -inf;
best_set = [];

subsets = nchoosek(visible_ids, m);
for i = 1:size(subsets, 1)
    cand = subsets(i, :);

    local_score = build_window_objective_singleloop(cand, caseData, k, prev_ids, cfg);
    outer_bonus = mean(prior_map(cand));

    total_score = local_score + prior_weight * outer_bonus;

    if total_score > best_score
        best_score = total_score;
        best_set = cand;
    end
end

selected_ids = best_set;
end
