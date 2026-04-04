function out = select_pair_dualloop_continuous(pred, pair_bank, sat_pos, x_seq, F_seq, Cr, R_pair, ...
    weights, prev_pair, cfgScore)
%SELECT_PAIR_DUALLOOP_CONTINUOUS Select best pair under continuous outerB scheduling.

assert(isnumeric(pair_bank) && size(pair_bank,2) == 2, 'pair_bank must be [N x 2].');

nPairs = size(pair_bank, 1);
scores = zeros(nPairs, 1);
evals = cell(nPairs, 1);

for i = 1:nPairs
    pair = pair_bank(i,:);
    e = score_candidate_pair_closed_loop(pred, pair, sat_pos, x_seq, F_seq, Cr, R_pair, ...
        weights, prev_pair, cfgScore);
    scores(i) = e.score;
    evals{i} = e;
end

[best_score, idx_best] = max(scores);
best_pair = pair_bank(idx_best, :);
best_eval = evals{idx_best};

out = struct();
out.best_pair = best_pair;
out.best_score = best_score;
out.best_eval = best_eval;
out.scores = scores;
out.idx_best = idx_best;
out.pair_bank = pair_bank;
end
