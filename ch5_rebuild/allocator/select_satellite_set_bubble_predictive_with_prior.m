function selection = select_satellite_set_bubble_predictive_with_prior(cfg, ch5case, selection_trace_prefix, k_now, prior)
%SELECT_SATELLITE_SET_BUBBLE_PREDICTIVE_WITH_PRIOR
% Predictive selection with weak-prior tie-break.

horizon_steps = cfg.ch5r.r5.horizon_steps;
lambda_sw = cfg.ch5r.r5.lambda_sw;
eps_prior = cfg.ch5r.r8.eps_prior;

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
        e = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
        e.prior_score = score_tiebreak_with_static_prior(prior, pair);
        e.total_score = e.score + eps_prior * e.prior_score;
        evals{idx} = e;
    end
else
    for idx = 1:nPairs
        pair = pair_list(idx, :);
        e = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw);
        e.prior_score = score_tiebreak_with_static_prior(prior, pair);
        e.total_score = e.score + eps_prior * e.prior_score;
        evals{idx} = e;
    end
end

best_score = -inf;
best_pair = [];
best_eval = [];

for idx = 1:nPairs
    e = evals{idx};
    if e.total_score > best_score
        best_score = e.total_score;
        best_pair = e.pair;
        best_eval = e;
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
selection.n_pairs = nPairs;
end
