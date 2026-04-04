function selection = select_satellite_set_tracking_greedy(cfg, truth, satbank, candidates, k, prev_pair)
%SELECT_SATELLITE_SET_TRACKING_GREEDY
% Select a double-satellite pair from the same fixed constellation at time step k.
%
% Objective:
%   maximize trace(J_pair) - lambda_sw * switch_cost

if nargin < 6
    prev_pair = [];
end

sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;
lambda_sw = 0;
if isfield(cfg.ch5r, 'r4') && isfield(cfg.ch5r.r4, 'lambda_sw')
    lambda_sw = cfg.ch5r.r4.lambda_sw;
end

pair_list = candidates.pair_bank{k};
assert(~isempty(pair_list), 'No visible double-satellite pair available at k=%d.', k);

r_tgt = truth.r_eci_km(k, :);
Nsat = size(pair_list, 1);

best_score = -inf;
best_pair = [];
best_J = [];

for idx = 1:Nsat
    pair = pair_list(idx, :);
    r_sat_pair = [
        squeeze(satbank.r_eci_km(k, :, pair(1)));
        squeeze(satbank.r_eci_km(k, :, pair(2)))
    ];

    J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
    score_track = trace(J);

    switch_cost = 0;
    if ~isempty(prev_pair) && ~isequal(pair, prev_pair)
        switch_cost = 1;
    end

    score = score_track - lambda_sw * switch_cost;

    if score > best_score
        best_score = score;
        best_pair = pair;
        best_J = J;
    end
end

selection = struct();
selection.k = k;
selection.time_s = truth.t_s(k);
selection.pair = best_pair;
selection.J_pair = best_J;
selection.score = best_score;
selection.prev_pair = prev_pair;
selection.switch_flag = ~isempty(prev_pair) && ~isequal(best_pair, prev_pair);
selection.name = 'tracking_greedy_real_pair';
end
