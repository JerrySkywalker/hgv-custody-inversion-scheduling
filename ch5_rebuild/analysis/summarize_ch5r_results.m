function summary = summarize_ch5r_results(outX, policy_name)
%SUMMARIZE_CH5R_RESULTS  Build one-row summary struct for comparison table.

if nargin < 2 || isempty(policy_name)
    policy_name = 'unknown';
end

summary = struct();
summary.policy = string(policy_name);
summary.bubble_fraction = outX.result.bubble_metrics.bubble_fraction;
summary.bubble_time_s = outX.result.bubble_metrics.bubble_time_s;
summary.longest_bubble_time_s = outX.result.bubble_metrics.longest_bubble_time_s;
summary.max_bubble_depth = outX.result.bubble_metrics.max_bubble_depth;
summary.loc_total_time_s = outX.result.custody_metrics.loc_total_time_s;
summary.custody_ratio = outX.result.custody_metrics.custody_ratio;
summary.mean_rmse = outX.result.rmse_metrics.mean_rmse;
summary.min_margin = outX.result.requirement.min_margin;
summary.resource_score = outX.result.cost_metrics.resource_score;
summary.switch_count = outX.result.cost_metrics.switch_count;
end
