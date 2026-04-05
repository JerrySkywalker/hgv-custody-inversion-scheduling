function out = select_pair_bubble_correction(pred_state, pred_cov, pair_bank, sat_pos, model, Q, H_fun, R_single, Cr, Gamma_req, dt, window_len, prev_pair)
%SELECT_PAIR_BUBBLE_CORRECTION Select pair by lexicographic bubble correction rule.

assert(isnumeric(pair_bank) && size(pair_bank,2) == 2, 'pair_bank must be [N x 2].');

nPairs = size(pair_bank, 1);
cands = cell(nPairs, 1);

for i = 1:nPairs
    cands{i} = evaluate_pair_bubble_correction_candidate( ...
        pred_state, pred_cov, pair_bank(i,:), sat_pos, model, Q, H_fun, R_single, Cr, Gamma_req, dt, window_len, prev_pair);
end

best = cands{1};
best_idx = 1;

for i = 2:nPairs
    if compare_bubble_correction_candidates(cands{i}, best)
        best = cands{i};
        best_idx = i;
    end
end

out = struct();
out.best_idx = best_idx;
out.best_pair = best.pair;
out.best_eval = best;
out.all_candidates = cands;
end
