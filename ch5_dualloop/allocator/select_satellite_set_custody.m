function selected_ids = select_satellite_set_custody(caseData, k, prev_ids, cfg)
%SELECT_SATELLITE_SET_CUSTODY  Single-loop custody-oriented selection.

if nargin < 4 || isempty(cfg)
    cfg = default_ch5_params();
end

max_track_sats = cfg.ch5.max_track_sats;
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
    s = build_window_objective_singleloop(cand, caseData, k, prev_ids, cfg);
    if s > best_score
        best_score = s;
        best_set = cand;
    end
end

selected_ids = best_set;
end
