function sel = policy_bubble_predictive_with_prior(cfg, ch5case, selection_trace, k)
%POLICY_BUBBLE_PREDICTIVE_WITH_PRIOR
% Minimal R7 dual-loop shell:
% - outer loop A: detect precursor
% - outer loop B: if triggered, run predictive bubble scheduling
% - otherwise keep previous feasible pair
% - explicit tail mode after last valid full-window center

pair_list = ch5case.candidates.pair_bank{k};
sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;
last_valid_center = numel(ch5case.t_s) - ch5case.window.right_steps;

precursor = detect_bubble_precursor(cfg, ch5case, selection_trace, k);

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

% tail mode: no future full-window center remains
if k > last_valid_center
    prev_pair = [];
    if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair')
        prev_pair = selection_trace{k-1}.pair;
    end

    if ~isempty(prev_pair) && ismember(prev_pair, pair_list, 'rows')
        pair = prev_pair;
        name_str = 'dual_loop_tail_hold';
    else
        best_score = -inf;
        pair = pair_list(1,:);
        for idx = 1:size(pair_list,1)
            cand = pair_list(idx,:);
            r_tgt = ch5case.truth.r_eci_km(k, :);
            r_sat_pair = [
                squeeze(ch5case.satbank.r_eci_km(k, :, cand(1)));
                squeeze(ch5case.satbank.r_eci_km(k, :, cand(2)))
            ];
            J_try = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
            s_try = trace(J_try);
            if s_try > best_score
                best_score = s_try;
                pair = cand;
            end
        end
        name_str = 'dual_loop_tail_trace';
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
    sel.name = name_str;
    sel.n_pairs = size(pair_list,1);
    sel.triggered = false;
    sel.precursor = precursor;
    return;
end

if precursor.trigger
    sel = select_satellite_set_bubble_predictive(cfg, ch5case, selection_trace, k);
    sel.name = 'dual_loop_triggered_predictive';
    sel.triggered = true;
    sel.precursor = precursor;
    return;
end

% Non-trigger branch: keep previous feasible pair if possible; otherwise use light greedy fallback
reuse_prev = false;
if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair') ...
        && ~isempty(selection_trace{k-1}.pair)
    prev_pair = selection_trace{k-1}.pair;
    if ismember(prev_pair, pair_list, 'rows')
        reuse_prev = true;
        pair = prev_pair;
    end
end

if ~reuse_prev
    best_score = -inf;
    pair = pair_list(1,:);
    for idx = 1:size(pair_list,1)
        cand = pair_list(idx,:);
        r_tgt = ch5case.truth.r_eci_km(k, :);
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, cand(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, cand(2)))
        ];
        J_try = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
        s_try = trace(J_try);
        if s_try > best_score
            best_score = s_try;
            pair = cand;
        end
    end
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
