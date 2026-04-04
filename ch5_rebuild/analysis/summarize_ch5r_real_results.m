function summary = summarize_ch5r_real_results(outX, policy_name)
%SUMMARIZE_CH5R_REAL_RESULTS  Build one-row real-result summary struct.

if nargin < 2 || isempty(policy_name)
    policy_name = 'unknown';
end

summary = struct();
summary.policy = string(policy_name);

summary.bubble_steps = outX.result.bubble_metrics.bubble_steps;
summary.bubble_fraction = outX.result.bubble_metrics.bubble_fraction;
summary.bubble_time_s = outX.result.bubble_metrics.bubble_time_s;
summary.longest_bubble_time_s = outX.result.bubble_metrics.longest_bubble_time_s;
summary.max_bubble_depth = outX.result.bubble_metrics.max_bubble_depth;
summary.mean_bubble_depth = outX.result.bubble_metrics.mean_bubble_depth;

summary.loc_total_time_s = outX.result.custody_metrics.loc_total_time_s;
summary.custody_ratio = outX.result.custody_metrics.custody_ratio;

summary.mean_rmse = outX.result.rmse_metrics.mean_rmse;
summary.min_margin = outX.result.requirement.min_margin;

summary.switch_count = outX.result.cost_metrics.switch_count;
summary.resource_score = outX.result.cost_metrics.resource_score;

nonempty_count = 0;
for k = 1:numel(outX.selection_trace)
    if ~isempty(outX.selection_trace{k}.pair)
        nonempty_count = nonempty_count + 1;
    end
end
summary.observable_steps = nonempty_count;
end
