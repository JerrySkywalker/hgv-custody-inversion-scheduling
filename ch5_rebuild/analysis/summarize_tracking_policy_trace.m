function md = summarize_tracking_policy_trace(policy, policy_log_table, policy_log_summary, result)
%SUMMARIZE_TRACKING_POLICY_TRACE  Build markdown summary for R4 logging.

if nargin < 4
    error('policy, policy_log_table, policy_log_summary, result are required.');
end

bm = result.bubble_metrics;
rq = result.requirement;
ct = result.cost_metrics;

lines = {};
lines{end+1} = '# Phase R4 Tracking-Greedy Policy Log Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Policy thresholds';
lines{end+1} = '';
lines{end+1} = ['- tau_low: ', num2str(policy.tau_low, '%.12g')];
lines{end+1} = ['- tau_high: ', num2str(policy.tau_high, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 2. Selection behavior';
lines{end+1} = '';
lines{end+1} = ['- total_steps: ', num2str(policy_log_summary.total_steps)];
lines{end+1} = ['- switch_count: ', num2str(policy_log_summary.switch_count)];
lines{end+1} = ['- theta_star steps: ', num2str(policy_log_summary.star_steps)];
lines{end+1} = ['- theta_plus steps: ', num2str(policy_log_summary.plus_steps)];
lines{end+1} = ['- theta_plus fraction: ', num2str(policy_log_summary.plus_fraction, '%.6f')];
lines{end+1} = ['- mean gain: ', num2str(policy_log_summary.mean_gain, '%.12g')];
lines{end+1} = ['- max gain: ', num2str(policy_log_summary.max_gain, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 3. Bubble linkage';
lines{end+1} = '';
lines{end+1} = ['- bubble_steps: ', num2str(policy_log_summary.bubble_steps)];
lines{end+1} = ['- bubble_fraction: ', num2str(policy_log_summary.bubble_fraction, '%.6f')];
lines{end+1} = ['- result bubble_time_s: ', num2str(bm.bubble_time_s, '%.6f')];
lines{end+1} = ['- result max_bubble_depth: ', num2str(bm.max_bubble_depth, '%.12g')];
lines{end+1} = ['- result min_margin: ', num2str(rq.min_margin, '%.12g')];
lines{end+1} = ['- result resource_score: ', num2str(ct.resource_score, '%.6f')];
lines{end+1} = '';
lines{end+1} = '## 4. First 10 step logs';
lines{end+1} = '';
lines{end+1} = '| k | time_s | inst_lambda_min | theta | switch | Ns | gain | bubble |';
lines{end+1} = '|---:|---:|---:|---|---:|---:|---:|---:|';

n_show = min(10, height(policy_log_table));
for i = 1:n_show
    lines{end+1} = ['| ', num2str(policy_log_table.k(i)), ...
        ' | ', num2str(policy_log_table.time_s(i), '%.6f'), ...
        ' | ', num2str(policy_log_table.inst_lambda_min(i), '%.12g'), ...
        ' | ', char(policy_log_table.current_theta_name(i)), ...
        ' | ', num2str(double(policy_log_table.switch_flag(i))), ...
        ' | ', num2str(policy_log_table.Ns(i)), ...
        ' | ', num2str(policy_log_table.gain(i), '%.12g'), ...
        ' | ', num2str(double(policy_log_table.bubble_flag(i))), ' |'];
end

md = strjoin(lines, newline);
end
