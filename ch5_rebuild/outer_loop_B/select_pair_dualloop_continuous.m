function out = select_pair_dualloop_continuous(pred, pair_bank, sat_pos, x_seq, F_seq, Cr, R_pair, ...
    weights, prev_pair, cfgScore)
%SELECT_PAIR_DUALLOOP_CONTINUOUS Select best pair under continuous outerB scheduling.
%
% Updated in R8.5a:
%   near-score tie-break is enabled.

assert(isnumeric(pair_bank) && size(pair_bank,2) == 2, 'pair_bank must be [N x 2].');

nPairs = size(pair_bank, 1);
scores = zeros(nPairs, 1);
tie_metrics = zeros(nPairs, 1);
evals = cell(nPairs, 1);

for i = 1:nPairs
    pair = pair_bank(i,:);
    e = score_candidate_pair_closed_loop(pred, pair, sat_pos, x_seq, F_seq, Cr, R_pair, ...
        weights, prev_pair, cfgScore);
    scores(i) = e.score;
    tie_metrics(i) = e.tie_metric;
    evals{i} = e;
end

[score_sorted, idx_sorted] = sort(scores, 'descend');

idx_best = idx_sorted(1);
if nPairs >= 2
    gap12 = score_sorted(1) - score_sorted(2);
else
    gap12 = inf;
end

if nPairs >= 2 && gap12 < cfgScore.tie_break_gap
    top_mask = abs(scores - score_sorted(1)) < cfgScore.tie_break_gap;
    cand_idx = find(top_mask);
    [~, loc] = max(tie_metrics(cand_idx));
    idx_best = cand_idx(loc);
end

best_score = scores(idx_best);
best_pair = pair_bank(idx_best, :);
best_eval = evals{idx_best};

out = struct();
out.best_pair = best_pair;
out.best_score = best_score;
out.best_eval = best_eval;
out.scores = scores;
out.tie_metrics = tie_metrics;
out.idx_best = idx_best;
out.pair_bank = pair_bank;
out.gap12 = gap12;
end
