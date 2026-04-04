function out = select_pair_dualloop_continuous(pred, pair_bank, sat_pos, x_seq, F_seq, Cr, R_pair, ...
    weights, prev_pair, cfgScore)
%SELECT_PAIR_DUALLOOP_CONTINUOUS Select best pair under normalized multi-term scoring.
%
% Updated in R8.5b:
%   normalize candidate-bank components before forming the main score.

assert(isnumeric(pair_bank) && size(pair_bank,2) == 2, 'pair_bank must be [N x 2].');

nPairs = size(pair_bank, 1);
evals = cell(nPairs, 1);

raw_MG = zeros(nPairs, 1);
raw_PR = zeros(nPairs, 1);
raw_SC = zeros(nPairs, 1);
raw_RC = zeros(nPairs, 1);
tie_metrics = zeros(nPairs, 1);

for i = 1:nPairs
    pair = pair_bank(i,:);
    e = score_candidate_pair_closed_loop(pred, pair, sat_pos, x_seq, F_seq, Cr, R_pair, ...
        weights, prev_pair, cfgScore);
    evals{i} = e;
    raw_MG(i) = e.raw_MG;
    raw_PR(i) = e.raw_lambda_max_PR_plus;
    raw_SC(i) = e.raw_switch_cost;
    raw_RC(i) = e.raw_resource_cost;
    tie_metrics(i) = e.tie_metric;
end

norm_MG = local_minmax(raw_MG);
norm_PR = local_minmax(raw_PR);
norm_SC = local_minmax(raw_SC);
norm_RC = local_minmax(raw_RC);

scores = weights.beta_k * norm_MG ...
       - weights.alpha_k * norm_PR ...
       - weights.eta_k  * norm_SC ...
       - weights.mu_k   * norm_RC;

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

best_eval.score = best_score;
best_eval.norm_MG = norm_MG(idx_best);
best_eval.norm_PR = norm_PR(idx_best);
best_eval.norm_SC = norm_SC(idx_best);
best_eval.norm_RC = norm_RC(idx_best);

out = struct();
out.best_pair = best_pair;
out.best_score = best_score;
out.best_eval = best_eval;
out.scores = scores;
out.tie_metrics = tie_metrics;
out.idx_best = idx_best;
out.pair_bank = pair_bank;
out.gap12 = gap12;

out.raw_MG = raw_MG;
out.raw_PR = raw_PR;
out.raw_SC = raw_SC;
out.raw_RC = raw_RC;
out.norm_MG = norm_MG;
out.norm_PR = norm_PR;
out.norm_SC = norm_SC;
out.norm_RC = norm_RC;
end

function y = local_minmax(x)
xmin = min(x);
xmax = max(x);
den = xmax - xmin;
if den < 1e-12
    y = zeros(size(x));
else
    y = (x - xmin) / den;
end
end
