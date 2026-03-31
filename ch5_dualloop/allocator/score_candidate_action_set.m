function score = score_candidate_action_set(candidate_ids, caseData, k, cfg)
%SCORE_CANDIDATE_ACTION_SET  Minimal tracking-oriented score for candidate set.
%
% Phase 3 baseline:
%   - prefer more simultaneously selected visible satellites
%   - prefer lower average range when available

if nargin < 4 || isempty(cfg)
    cfg = default_ch5_params();
end

if isempty(candidate_ids)
    score = -inf;
    return;
end

score = numel(candidate_ids);

% Optional geometric refinement: closer satellites get slightly higher score.
if isfield(caseData, 'truth') && isfield(caseData.truth, 'r_eci_km') && ...
   isfield(caseData, 'satbank') && isfield(caseData.satbank, 'r_eci_km')

    r_tgt = caseData.truth.r_eci_km(k, :);
    ranges = zeros(numel(candidate_ids), 1);

    for i = 1:numel(candidate_ids)
        sid = candidate_ids(i);
        r_sat = squeeze(caseData.satbank.r_eci_km(k, :, sid));
        ranges(i) = norm(r_sat(:).' - r_tgt);
    end

    score = score - 1e-3 * mean(ranges);
end
end
