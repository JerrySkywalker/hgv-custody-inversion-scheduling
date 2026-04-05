function selection = select_pair_bubble_correction_real_kernel(cfg, ch5case, selection_trace_prefix, k_now)
%SELECT_PAIR_BUBBLE_CORRECTION_REAL_KERNEL
% R8-C.3 lexicographic bubble correction using the same real future-window kernel as R5-real.

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
        evals{idx} = evaluate_pair_bubble_correction_candidate_real_kernel(cfg, ch5case, selection_trace_prefix, pair, k_now);
    end
else
    for idx = 1:nPairs
        pair = pair_list(idx, :);
        evals{idx} = evaluate_pair_bubble_correction_candidate_real_kernel(cfg, ch5case, selection_trace_prefix, pair, k_now);
    end
end

best_eval = evals{1};
best_pair = best_eval.pair;

for idx = 2:nPairs
    e = evals{idx};
    if compare_bubble_correction_candidates(e, best_eval)
        best_eval = e;
        best_pair = e.pair;
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
selection.score = best_eval.Xi_B;
selection.prev_pair = [];
selection.switch_flag = false;
selection.name = 'bubble_correction_real_kernel_pair';
selection.eval = best_eval;
selection.n_pairs = nPairs;
end
