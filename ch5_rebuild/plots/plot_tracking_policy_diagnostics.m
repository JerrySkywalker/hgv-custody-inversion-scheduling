function paths = plot_tracking_policy_diagnostics(policy_log_table, out_dir, stamp)
%PLOT_TRACKING_POLICY_DIAGNOSTICS  Save diagnostic plots for R4 logging.

if nargin < 2 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 3 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

paths = struct();

% Figure 1: instantaneous lambda_min vs thresholds
fig1 = figure('Visible', 'off');
plot(policy_log_table.time_s, policy_log_table.inst_lambda_min, 'LineWidth', 1.5);
hold on
plot(policy_log_table.time_s, policy_log_table.tau_low, '--', 'LineWidth', 1.2);
plot(policy_log_table.time_s, policy_log_table.tau_high, '--', 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('Instantaneous \lambda_{min}(Y_k)');
title('Tracking Policy Diagnostics: Instantaneous Information vs Thresholds');
grid on
paths.inst_lambda_png = fullfile(out_dir, ['plot_tracking_policy_inst_lambda_' stamp '.png']);
saveas(fig1, paths.inst_lambda_png);
close(fig1);

% Figure 2: theta selection trace
fig2 = figure('Visible', 'off');
theta_code = zeros(height(policy_log_table), 1);
theta_code(policy_log_table.current_theta_name == "theta_star") = 0;
theta_code(policy_log_table.current_theta_name == "theta_plus") = 1;
stairs(policy_log_table.time_s, theta_code, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Selection Code');
title('Tracking Policy Diagnostics: Selection Trace');
ylim([-0.1 1.1]);
yticks([0 1]);
yticklabels({'theta\_star','theta\_plus'});
grid on
paths.selection_trace_png = fullfile(out_dir, ['plot_tracking_policy_selection_trace_' stamp '.png']);
saveas(fig2, paths.selection_trace_png);
close(fig2);

% Figure 3: gain trace
fig3 = figure('Visible', 'off');
plot(policy_log_table.time_s, policy_log_table.gain, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Gain');
title('Tracking Policy Diagnostics: Gain Trace');
grid on
paths.gain_trace_png = fullfile(out_dir, ['plot_tracking_policy_gain_trace_' stamp '.png']);
saveas(fig3, paths.gain_trace_png);
close(fig3);
end
