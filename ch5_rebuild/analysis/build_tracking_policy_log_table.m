function [policy_log_table, policy_log_summary] = build_tracking_policy_log_table(ch5case_r4, policy, selection_trace, gain_trace, bubble)
%BUILD_TRACKING_POLICY_LOG_TABLE  Build step-level logging table for R4.

if nargin < 5
    error('ch5case_r4, policy, selection_trace, gain_trace, bubble are required.');
end

N = numel(ch5case_r4.time_s);

k_col = zeros(N,1);
time_col = zeros(N,1);
inst_lambda_col = zeros(N,1);
tau_low_col = zeros(N,1);
tau_high_col = zeros(N,1);
prev_theta_col = strings(N,1);
curr_theta_col = strings(N,1);
switch_col = false(N,1);
Ns_col = zeros(N,1);
gain_col = zeros(N,1);
bubble_col = false(N,1);

prev_name = "theta_star";
for k = 1:N
    theta_k = selection_trace{k}.theta;
    curr_name = local_theta_name(theta_k, policy);

    k_col(k) = k;
    time_col(k) = ch5case_r4.time_s(k);
    inst_lambda_col(k) = policy.inst_lambda_min(k);
    tau_low_col(k) = policy.tau_low;
    tau_high_col(k) = policy.tau_high;
    prev_theta_col(k) = prev_name;
    curr_theta_col(k) = curr_name;
    switch_col(k) = curr_name ~= prev_name;
    Ns_col(k) = theta_k.Ns;
    gain_col(k) = gain_trace(k);
    bubble_col(k) = bubble.is_bubble(k);

    prev_name = curr_name;
end

policy_log_table = table( ...
    k_col, time_col, inst_lambda_col, tau_low_col, tau_high_col, ...
    prev_theta_col, curr_theta_col, switch_col, Ns_col, gain_col, bubble_col, ...
    'VariableNames', { ...
    'k','time_s','inst_lambda_min','tau_low','tau_high', ...
    'prev_theta_name','current_theta_name','switch_flag','Ns','gain','bubble_flag'});

policy_log_summary = log_ch5r_policy_summary(policy_log_table);
end

function name = local_theta_name(theta_k, policy)
if isequal(theta_k, policy.theta_plus)
    name = "theta_plus";
elseif isequal(theta_k, policy.theta_star)
    name = "theta_star";
else
    name = "theta_unknown";
end
end
