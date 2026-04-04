function row = log_ch5r_policy_step(k, time_s, inst_lambda_min, tau_low, tau_high, prev_theta_name, current_theta_name, switch_flag, Ns, gain, bubble_flag)
%LOG_CH5R_POLICY_STEP  Build one policy-step log row for R4 analysis.

if nargin < 11
    error('log_ch5r_policy_step requires 11 inputs.');
end

row = struct();
row.k = k;
row.time_s = time_s;
row.inst_lambda_min = inst_lambda_min;
row.tau_low = tau_low;
row.tau_high = tau_high;
row.prev_theta_name = string(prev_theta_name);
row.current_theta_name = string(current_theta_name);
row.switch_flag = logical(switch_flag);
row.Ns = Ns;
row.gain = gain;
row.bubble_flag = logical(bubble_flag);
end
