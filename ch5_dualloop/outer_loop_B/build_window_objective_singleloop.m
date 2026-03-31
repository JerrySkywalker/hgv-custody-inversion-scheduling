function score = build_window_objective_singleloop(candidate_ids, caseData, k, prev_ids, cfg)
%BUILD_WINDOW_OBJECTIVE_SINGLELOOP  Threshold-sensitive single-loop custody objective.
%
% Phase 5C:
%   score = + alpha * mean_future
%           - gap_weight * worst_gap
%           - beta * mean_gap
%           - outage_weight * outage_frac
%           - gamma * switch_cost
%
% where future risk is defined relative to custody_phi_threshold.

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

if isempty(candidate_ids)
    score = -inf;
    return;
end

W = cfg.ch5.window_steps;
alpha = cfg.ch5.custody_alpha;
beta = cfg.ch5.custody_beta;
gamma = cfg.ch5.custody_gamma;
gap_weight = cfg.ch5.custody_gap_weight;
outage_weight = cfg.ch5.custody_outage_weight;
phi_th = cfg.ch5.custody_phi_threshold;
max_track_sats = cfg.ch5.max_track_sats;

N = size(caseData.candidates.visible_mask, 1);
k2 = min(N, k + W - 1);

future_geom = zeros(k2-k+1, 1);

for tau = k:k2
    vis_tau = caseData.candidates.visible_mask(tau, candidate_ids);

    if ~all(vis_tau)
        future_geom(tau-k+1) = 0;
        continue;
    end

    count_term = numel(candidate_ids) / max_track_sats;
    count_term = max(0, min(1, count_term));

    r_tgt = caseData.truth.r_eci_km(tau, :);
    ranges = zeros(numel(candidate_ids), 1);

    for i = 1:numel(candidate_ids)
        sid = candidate_ids(i);
        r_sat = squeeze(caseData.satbank.r_eci_km(tau, :, sid));
        ranges(i) = norm(r_sat(:).' - r_tgt);
    end

    avg_range_km = mean(ranges);
    range_term = 1 / (1 + avg_range_km / 2000);

    future_geom(tau-k+1) = min(count_term, range_term);
end

gap = max(0, phi_th - future_geom);

worst_gap = max(gap);
mean_gap = mean(gap);
outage_frac = mean(gap > 0);
mean_future = mean(future_geom);

if isempty(prev_ids)
    switch_cost = 0;
else
    stay = numel(intersect(prev_ids, candidate_ids));
    switch_cost = 1 - stay / max_track_sats;
end

score = ...
    + alpha * mean_future ...
    - gap_weight * worst_gap ...
    - beta * mean_gap ...
    - outage_weight * outage_frac ...
    - gamma * switch_cost;
end
