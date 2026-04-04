function sel = policy_bubble_predictive_with_prior(cfg, ch5case, selection_trace, k)
%POLICY_BUBBLE_PREDICTIVE_WITH_PRIOR
% Minimal R7 dual-loop shell:
% - outer loop A: detect precursor
% - outer loop B: if triggered, run predictive bubble scheduling
% - otherwise keep previous feasible pair

precursor = detect_bubble_precursor(cfg, ch5case, selection_trace, k);

pair_list = ch5case.candidates.pair_bank{k};
sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;

if isempty(pair_list)
    sel = struct( ...
        'k', k, ...
        'time_s', ch5case.t_s(k), ...
        'pair', [], ...
        'J_pair', zeros(3,3), ...
        'score', -inf, ...
        'prev_pair', [], ...
        'switch_flag', false, ...
        'name', 'dual_loop_empty', ...
        'n_pairs', 0, ...
        'triggered', precursor.trigger, ...
        'precursor', precursor);
    return;
end

if precursor.trigger
    sel = select_satellite_set_bubble_predictive(cfg, ch5case, selection_trace, k);
    sel.name = 'dual_loop_triggered_predictive';
    sel.triggered = true;
    sel.precursor = precursor;
    return;
end

% Non-trigger branch: keep previous feasible pair if possible; otherwise use a light greedy fallback
reuse_prev = false;
if k > 1 && ~isempty(selection_trace{k-1}.pair)
    prev_pair = selection_trace{k-1}.pair;
    if ismember(prev_pair, pair_list, 'rows')
        reuse_prev = true;
        pair = prev_pair;
    end
end

if ~reuse_prev
    % light fallback: choose first visible pair
    pair = pair_list(1,:);
end

r_tgt = ch5case.truth.r_eci_km(k, :);
r_sat_pair = [
    squeeze(ch5case.satbank.r_eci_km(k, :, pair(1)));
    squeeze(ch5case.satbank.r_eci_km(k, :, pair(2)))
];
J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);

sel = struct();
sel.k = k;
sel.time_s = ch5case.t_s(k);
sel.pair = pair;
sel.J_pair = J;
sel.score = trace(J);
sel.prev_pair = [];
sel.switch_flag = false;
sel.name = 'dual_loop_hold_or_fallback';
sel.n_pairs = size(pair_list,1);
sel.triggered = false;
sel.precursor = precursor;
end
