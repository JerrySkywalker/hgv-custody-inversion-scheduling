function selection = select_satellite_set_bubble_predictive_with_prior(cfg, ch5case, selection_trace_prefix, k_now, prior)
%SELECT_SATELLITE_SET_BUBBLE_PREDICTIVE_WITH_PRIOR
% Predictive selection with optional candidate pruning + close-score prior amplification.
%
% Robustness fix:
% - if all predictive scores become invalid / NaN / -Inf, fall back
%   to a stable visible pair instead of crashing.

horizon_steps = cfg.ch5r.r5.horizon_steps;
lambda_sw = cfg.ch5r.r5.lambda_sw;

pair_list_full = ch5case.candidates.pair_bank{k_now};
assert(~isempty(pair_list_full), 'No visible double-satellite pair available at k=%d.', k_now);

pair_list = prune_candidate_pairs_with_weak_prior(cfg, prior, pair_list_full);

nPairsFull = size(pair_list_full, 1);
nPairsUsed = size(pair_list, 1);

evals = cell(nPairsUsed, 1);

use_parallel = false;
if isfield(cfg.ch5r.r5, 'parallel') && isfield(cfg.ch5r.r5.parallel, 'enable')
    use_parallel = logical(cfg.ch5r.r5.parallel.enable);
end

if use_parallel && nPairsUsed > 1
    parfor idx = 1:nPairsUsed
        pair = pair_list(idx, :);
        e = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
        e.prior_score = score_tiebreak_with_static_prior(prior, pair);
        evals{idx} = e;
    end
else
    for idx = 1:nPairsUsed
        pair = pair_list(idx, :);
        e = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
        e.prior_score = score_tiebreak_with_static_prior(prior, pair);
        evals{idx} = e;
    end
end

base_scores = -inf(nPairsUsed, 1);
prior_scores = zeros(nPairsUsed, 1);

for idx = 1:nPairsUsed
    if isfield(evals{idx}, 'score') && ~isempty(evals{idx}.score) && isfinite(evals{idx}.score)
        base_scores(idx) = evals{idx}.score;
    end
    if isfield(evals{idx}, 'prior_score') && ~isempty(evals{idx}.prior_score) && isfinite(evals{idx}.prior_score)
        prior_scores(idx) = evals{idx}.prior_score;
    end
end

[total_scores, gain_meta] = apply_close_score_prior_gain(cfg, prior_scores, base_scores);

best_score = -inf;
best_pair = [];
best_eval = [];
best_idx = 0;

for idx = 1:nPairsUsed
    evals{idx}.total_score = total_scores(idx);
    evals{idx}.gain_meta = gain_meta;

    if ~isfinite(total_scores(idx))
        continue;
    end

    if total_scores(idx) > best_score
        best_score = total_scores(idx);
        best_pair = evals{idx}.pair;
        best_eval = evals{idx};
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

    if ~isempty(prev_pair) && ismember(prev_pair, pair_list_full, 'rows')
        best_pair = prev_pair;
        best_score = -1e12;
        best_eval = struct( ...
            'pair', best_pair, ...
            'min_future_lambda', NaN, ...
            'switch_cost', 0, ...
            'score', best_score, ...
            'prior_score', 0, ...
            'total_score', best_score, ...
            'gain_meta', struct());
    else
        best_pair = pair_list_full(1,:);
        best_score = -1e12;
        best_eval = struct( ...
            'pair', best_pair, ...
            'min_future_lambda', NaN, ...
            'switch_cost', NaN, ...
            'score', best_score, ...
            'prior_score', 0, ...
            'total_score', best_score, ...
            'gain_meta', struct());
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
selection.score = best_eval.total_score;
selection.prev_pair = [];
selection.switch_flag = false;
selection.name = 'bubble_predictive_with_weak_prior';
selection.eval = best_eval;
selection.n_pairs_full = nPairsFull;
selection.n_pairs_used = nPairsUsed;
selection.best_idx = best_idx;
end
