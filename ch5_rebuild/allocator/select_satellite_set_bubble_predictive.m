function selection = select_satellite_set_bubble_predictive(cfg, ch5case, selection_trace_prefix, k_now)
%SELECT_SATELLITE_SET_BUBBLE_PREDICTIVE
% Choose the visible pair that maximizes the future worst-window lower bound.
%
% Robustness fix:
% - if all predictive scores are invalid / NaN / -Inf near the tail, fall back
%   to a stable currently-visible pair instead of crashing.

horizon_steps = cfg.ch5r.r5.horizon_steps;
lambda_sw = cfg.ch5r.r5.lambda_sw;

pair_list = ch5case.candidates.pair_bank{k_now};
assert(~isempty(pair_list), 'No visible double-satellite pair available at k=%d.', k_now);

nPairs = size(pair_list, 1);
evals = cell(nPairs, 1);

use_parallel = false;
if isfield(cfg.ch5r.r5, 'parallel') && isfield(cfg.ch5r.r5.parallel, 'enable')
    use_parallel = logical(cfg.ch5r.r5.parallel.enable);
end

if use_parallel && nPairs > 1
    parfor idx = 1:nPairs
        pair = pair_list(idx, :);
        evals{idx} = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
    end
else
    for idx = 1:nPairs
        pair = pair_list(idx, :);
        evals{idx} = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
    end
end

best_score = -inf;
best_pair = [];
best_eval = [];
best_idx = 0;

for idx = 1:nPairs
    e = evals{idx};
    if ~isfield(e, 'score') || isempty(e.score) || ~isfinite(e.score)
        continue;
    end
    if e.score > best_score
        best_score = e.score;
        best_pair = e.pair;
        best_eval = e;
        best_idx = idx;
    end
end

% --- robust fallback branch ---
if isempty(best_pair)
    prev_pair = [];
    if k_now > 1 && numel(selection_trace_prefix) >= (k_now-1) ...
            && isstruct(selection_trace_prefix{k_now-1}) ...
            && isfield(selection_trace_prefix{k_now-1}, 'pair')
        prev_pair = selection_trace_prefix{k_now-1}.pair;
    end

    if ~isempty(prev_pair) && ismember(prev_pair, pair_list, 'rows')
        best_pair = prev_pair;
        best_score = -1e12;
        best_eval = struct( ...
            'pair', best_pair, ...
            'min_future_lambda', NaN, ...
            'switch_cost', 0, ...
            'score', best_score, ...
            'pred', []);
    else
        best_pair = pair_list(1,:);
        best_score = -1e12;
        best_eval = struct( ...
            'pair', best_pair, ...
            'min_future_lambda', NaN, ...
            'switch_cost', NaN, ...
            'score', best_score, ...
            'pred', []);
    end
end

sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;
r_tgt = ch5case.truth.r_eci_km(k_now, :);
r_sat_pair = [
    squeeze(ch5case.satbank.r_eci_km(k_now, :, best_pair(1)));
    squeeze(ch5case.satbank.r_eci_km(k_now, :, best_pair(2)))
];
J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);

selection = struct();
selection.k = k_now;
selection.time_s = ch5case.t_s(k_now);
selection.pair = best_pair;
selection.J_pair = J;
selection.score = best_score;
selection.prev_pair = [];
selection.switch_flag = false;
selection.name = 'bubble_predictive_real_pair';
selection.eval = best_eval;
selection.n_pairs = nPairs;
selection.best_idx = best_idx;
end
