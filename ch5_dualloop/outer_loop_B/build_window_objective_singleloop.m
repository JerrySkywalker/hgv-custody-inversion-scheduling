function score = build_window_objective_singleloop(candidate_ids, caseData, k, prev_ids, cfg)
%BUILD_WINDOW_OBJECTIVE_SINGLELOOP  Single-loop custody objective for one candidate set.
%
% Phase 5B strengthened objective:
%   score = alpha * worst_future_geom
%         + (1-alpha) * avg_future_geom
%         - beta * std_future_geom
%         - gamma * switch_cost

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

worst_future = min(future_geom);
avg_future = mean(future_geom);
std_future = std(future_geom);

if isempty(prev_ids)
    switch_cost = 0;
else
    stay = numel(intersect(prev_ids, candidate_ids));
    switch_cost = 1 - stay / max_track_sats;
end

score = alpha * worst_future + (1 - alpha) * avg_future - beta * std_future - gamma * switch_cost;
end
