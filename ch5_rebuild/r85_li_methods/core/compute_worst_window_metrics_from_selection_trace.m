function out = compute_worst_window_metrics_from_selection_trace(ch5case, selection_trace, tag)
%COMPUTE_WORST_WINDOW_METRICS_FROM_SELECTION_TRACE
% R8.6a:
%   Compute average metrics and worst-window metrics from a selection trace.

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');

rep = compute_formal_bubble_metrics_from_selection_trace(ch5case, selection_trace, tag);

lambda_series = rep.lambda_min_window(:);
bubble_mask = rep.bubble_mask(:);
bubble_depth = rep.bubble_depth(:);

n_steps = numel(lambda_series);
assert(n_steps >= 1, 'lambda series is empty.');

[min_lambda, idx_worst] = min(lambda_series);

mean_lambda = mean(lambda_series, 'omitnan');
median_lambda = median(lambda_series, 'omitnan');

% longest continuous bubble span
longest_bubble_span = 0;
current_span = 0;
for k = 1:n_steps
    if bubble_mask(k)
        current_span = current_span + 1;
        if current_span > longest_bubble_span
            longest_bubble_span = current_span;
        end
    else
        current_span = 0;
    end
end

mean_bubble_depth = mean(bubble_depth(bubble_mask), 'omitnan');
if isempty(mean_bubble_depth) || isnan(mean_bubble_depth)
    mean_bubble_depth = 0;
end

summary = struct();
summary.tag = string(tag);
summary.n_steps = n_steps;
summary.mean_lambda_min_window = mean_lambda;
summary.median_lambda_min_window = median_lambda;
summary.min_lambda_min_window = min_lambda;
summary.worst_window_index = idx_worst;
summary.bubble_steps = rep.summary.bubble_steps;
summary.bubble_time_s = rep.summary.bubble_time_s;
summary.max_bubble_depth = rep.summary.max_bubble_depth;
summary.mean_bubble_depth = mean_bubble_depth;
summary.longest_bubble_span = longest_bubble_span;
summary.switch_count = rep.summary.switch_count;
summary.resource_score = rep.summary.resource_score;
summary.n_missing_pair_steps = rep.summary.n_missing_pair_steps;
summary.gamma_req = rep.summary.gamma_req;

out = struct();
out.summary = summary;
out.lambda_series = lambda_series;
out.bubble_mask = bubble_mask;
out.bubble_depth = bubble_depth;
out.rep = rep;
end
