function out = analyze_policy_difference_window_effect(ch5case, trace_ref, trace_new, tag_ref, tag_new)
%ANALYZE_POLICY_DIFFERENCE_WINDOW_EFFECT
% R8.5f.3:
%   Analyze why more switches may fail to reduce bubble.
%
% Compare two stepwise policies at the window-information level.

rep_ref = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_ref, tag_ref);
rep_new = compute_formal_bubble_metrics_from_selection_trace(ch5case, trace_new, tag_new);

n_steps = numel(trace_ref);
assert(numel(trace_new) == n_steps, 'trace length mismatch.');

pair_diff_mask = false(n_steps,1);
for k = 1:n_steps
    p1 = local_get_pair(trace_ref{k});
    p2 = local_get_pair(trace_new{k});
    if isempty(p1) || isempty(p2)
        pair_diff_mask(k) = false;
    else
        pair_diff_mask(k) = any(p1(:) ~= p2(:));
    end
end

delta_lambda = rep_new.lambda_min_window - rep_ref.lambda_min_window;

gamma_req = rep_ref.summary.gamma_req;
ref_bubble = rep_ref.bubble_mask;
new_bubble = rep_new.bubble_mask;

improved_mask = delta_lambda > 1e-9;
worsened_mask = delta_lambda < -1e-9;
unchanged_mask = ~improved_mask & ~worsened_mask;

threshold_cross_up = ref_bubble & ~new_bubble;
threshold_cross_down = ~ref_bubble & new_bubble;

summary = struct();
summary.tag_ref = string(tag_ref);
summary.tag_new = string(tag_new);
summary.n_steps = n_steps;
summary.n_pair_diff_steps = sum(pair_diff_mask);
summary.n_improved_steps = sum(improved_mask);
summary.n_worsened_steps = sum(worsened_mask);
summary.n_unchanged_steps = sum(unchanged_mask);
summary.mean_delta_lambda_all = mean(delta_lambda, 'omitnan');
summary.mean_delta_lambda_on_pair_diff = mean(delta_lambda(pair_diff_mask), 'omitnan');
summary.n_threshold_cross_up = sum(threshold_cross_up);
summary.n_threshold_cross_down = sum(threshold_cross_down);
summary.n_pair_diff_but_not_improved = sum(pair_diff_mask & ~improved_mask);
summary.n_pair_diff_and_improved = sum(pair_diff_mask & improved_mask);

diff_table = table( ...
    (1:n_steps)', ...
    pair_diff_mask, ...
    rep_ref.lambda_min_window, ...
    rep_new.lambda_min_window, ...
    delta_lambda, ...
    ref_bubble, ...
    new_bubble, ...
    threshold_cross_up, ...
    threshold_cross_down, ...
    'VariableNames', { ...
        'step_index', ...
        'pair_diff', ...
        'lambda_ref', ...
        'lambda_new', ...
        'delta_lambda', ...
        'bubble_ref', ...
        'bubble_new', ...
        'threshold_cross_up', ...
        'threshold_cross_down'});

out = struct();
out.summary = summary;
out.diff_table = diff_table;
out.rep_ref = rep_ref;
out.rep_new = rep_new;
end

function p = local_get_pair(rec)
p = [];
if isstruct(rec) && isfield(rec, 'best_pair') && ~isempty(rec.best_pair)
    p = rec.best_pair(:).';
    if numel(p) >= 2
        p = p(1:2);
    else
        p = [];
    end
end
end
