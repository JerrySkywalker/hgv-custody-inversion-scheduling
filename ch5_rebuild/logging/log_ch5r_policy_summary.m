function summary = log_ch5r_policy_summary(policy_log_table)
%LOG_CH5R_POLICY_SUMMARY  Summarize step-level policy log table.

if nargin < 1 || isempty(policy_log_table)
    error('policy_log_table is required.');
end

summary = struct();
summary.total_steps = height(policy_log_table);
summary.switch_count = nnz(policy_log_table.switch_flag);
summary.plus_steps = nnz(policy_log_table.current_theta_name == "theta_plus");
summary.star_steps = nnz(policy_log_table.current_theta_name == "theta_star");
summary.bubble_steps = nnz(policy_log_table.bubble_flag);

if summary.total_steps > 0
    summary.plus_fraction = summary.plus_steps / summary.total_steps;
    summary.star_fraction = summary.star_steps / summary.total_steps;
    summary.bubble_fraction = summary.bubble_steps / summary.total_steps;
    summary.mean_gain = mean(policy_log_table.gain);
    summary.max_gain = max(policy_log_table.gain);
    summary.min_inst_lambda_min = min(policy_log_table.inst_lambda_min);
    summary.max_inst_lambda_min = max(policy_log_table.inst_lambda_min);
else
    summary.plus_fraction = 0;
    summary.star_fraction = 0;
    summary.bubble_fraction = 0;
    summary.mean_gain = NaN;
    summary.max_gain = NaN;
    summary.min_inst_lambda_min = NaN;
    summary.max_inst_lambda_min = NaN;
end
end
