function sel = select_satellite_set_r9_pipe_feedback(cfg, ch5case, selection_trace_prefix, k_now, x_pred, P_pred, model)
%SELECT_SATELLITE_SET_R9_PIPE_FEEDBACK
% Choose the candidate pair with maximal R9 pipe-feedback score.

pair_list = ch5case.candidates.pair_bank{k_now};
assert(~isempty(pair_list), 'No visible pair at k=%d.', k_now);

nPairs = size(pair_list,1);
best_score = -inf;
best_pair = [];
best_eval = [];

for i = 1:nPairs
    pair = pair_list(i,:);
    e = evaluate_candidate_r9_score(cfg, ch5case, selection_trace_prefix, k_now, pair, x_pred, P_pred, model);
    if isfinite(e.score) && e.score > best_score
        best_score = e.score;
        best_pair = pair;
        best_eval = e;
    end
end

if isempty(best_pair)
    best_pair = pair_list(1,:);
    best_eval = evaluate_candidate_r9_score(cfg, ch5case, selection_trace_prefix, k_now, best_pair, x_pred, P_pred, model);
    best_score = best_eval.score;
end

sel = struct();
sel.k = k_now;
sel.time_s = ch5case.t_s(k_now);
sel.pair = best_pair;
sel.score = best_score;
sel.eval = best_eval;
sel.name = 'r9_pipe_feedback_pair';
sel.n_pairs = nPairs;
end
