function score = build_window_objective_singleloop(candidate_ids, caseData, k, prev_ids, cfg)
%BUILD_WINDOW_OBJECTIVE_SINGLELOOP  Longest-bad-run-first single-loop custody objective.
%
% Phase 5D:
%   score = - w1 * longest_bad_run_norm
%           - w2 * worst_gap
%           - w3 * outage_frac
%           - w4 * mean_gap
%           - w5 * switch_cost
%           + w6 * mean_future
%
% The design is intentionally near-lexicographic:
%   1) cut longest bad chain
%   2) reduce worst threshold gap
%   3) reduce bad fraction
%   4) reduce average gap
%   5) keep switch cost small
%   6) only then prefer higher average future quality

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

if isempty(candidate_ids)
    score = -inf;
    return;
end

W = cfg.ch5.window_steps;
phi_th = cfg.ch5.custody_phi_threshold;
max_track_sats = cfg.ch5.max_track_sats;

w1 = cfg.ch5.custody_longest_bad_weight;
w2 = cfg.ch5.custody_worst_gap_weight;
w3 = cfg.ch5.custody_outage_frac_weight;
w4 = cfg.ch5.custody_mean_gap_weight;
w5 = cfg.ch5.custody_switch_weight;
w6 = cfg.ch5.custody_mean_future_weight;

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
is_bad = gap > 0;

worst_gap = max(gap);
mean_gap = mean(gap);
outage_frac = mean(is_bad);
mean_future = mean(future_geom);

max_run = 0;
run_len = 0;
for idx = 1:numel(is_bad)
    if is_bad(idx)
        run_len = run_len + 1;
        if run_len > max_run
            max_run = run_len;
        end
    else
        run_len = 0;
    end
end
longest_bad_run_norm = max_run / W;

if isempty(prev_ids)
    switch_cost = 0;
else
    stay = numel(intersect(prev_ids, candidate_ids));
    switch_cost = 1 - stay / max_track_sats;
end

score = ...
    - w1 * longest_bad_run_norm ...
    - w2 * worst_gap ...
    - w3 * outage_frac ...
    - w4 * mean_gap ...
    - w5 * switch_cost ...
    + w6 * mean_future;
end
