function score = build_window_objective_singleloop(candidate_ids, caseData, k, prev_ids, cfg)
%BUILD_WINDOW_OBJECTIVE_SINGLELOOP  Single-loop custody objective for one candidate set.
%
% score = alpha * worst_future + (1-alpha) * avg_future - gamma * switch_cost

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

if isempty(candidate_ids)
    score = -inf;
    return;
end

W = cfg.ch5.window_steps;
alpha = cfg.ch5.custody_alpha;
gamma = cfg.ch5.custody_gamma;
max_track_sats = cfg.ch5.max_track_sats;

N = size(caseData.candidates.visible_mask, 1);
k2 = min(N, k + W - 1);

future_norm = zeros(k2-k+1, 1);
for tau = k:k2
    vis_tau = caseData.candidates.visible_mask(tau, candidate_ids);
    future_norm(tau-k+1) = sum(vis_tau) / max_track_sats;
end

worst_future = min(future_norm);
avg_future = mean(future_norm);

if isempty(prev_ids)
    switch_cost = 0;
else
    stay = numel(intersect(prev_ids, candidate_ids));
    switch_cost = 1 - stay / max_track_sats;
end

score = alpha * worst_future + (1 - alpha) * avg_future - gamma * switch_cost;
end
