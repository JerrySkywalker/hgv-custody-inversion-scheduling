function selected_ids = select_satellite_set_tracking(caseData, k, cfg)
%SELECT_SATELLITE_SET_TRACKING  Minimal tracking-oriented selection.
%
% Phase 3 baseline:
%   - choose up to max_track_sats visible satellites
%   - prefer larger cardinality and then smaller average range

if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || ~isfield(cfg.ch5, 'max_track_sats')
    max_track_sats = 2;
else
    max_track_sats = cfg.ch5.max_track_sats;
end

visible_ids = caseData.candidates.sets{k};
visible_ids = visible_ids(:).';

if isempty(visible_ids)
    selected_ids = [];
    return;
end

if numel(visible_ids) <= max_track_sats
    selected_ids = visible_ids;
    return;
end

best_score = -inf;
best_set = [];

subsets = nchoosek(visible_ids, max_track_sats);
for i = 1:size(subsets, 1)
    cand = subsets(i, :);
    s = score_candidate_action_set(cand, caseData, k, cfg);
    if s > best_score
        best_score = s;
        best_set = cand;
    end
end

selected_ids = best_set;
end
