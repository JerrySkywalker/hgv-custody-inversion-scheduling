function fig_paths = plot_tracking_vs_static_summary(out3, out4, out_dir, stamp)
%PLOT_TRACKING_VS_STATIC_SUMMARY  Generate minimal comparison plots for R4c.

if nargin < 3 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 4 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig_paths = struct();

% 1) lambda_min timeline comparison
fig1 = figure('Visible', 'off');
plot(out3.state_trace.time_s, out3.state_trace.lambda_min, 'LineWidth', 1.5);
hold on
plot(out4.state_trace.time_s, out4.state_trace.lambda_min, 'LineWidth', 1.5);
yline(out3.state_trace.gamma_req, '--', 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('\lambda_{min}(Y_W)');
title('Static-Hold vs Tracking-Greedy: \lambda_{min}(Y_W) Timeline');
legend({'static\_hold','tracking\_greedy','\gamma_{req}'}, 'Location', 'best');
grid on
fig_paths.lambda_timeline_png = fullfile(out_dir, ['plot_r4c_lambda_timeline_' stamp '.png']);
saveas(fig1, fig_paths.lambda_timeline_png);
close(fig1);

% 2) bubble flag comparison
fig2 = figure('Visible', 'off');
stairs(out3.state_trace.time_s, double(out3.state_trace.is_bubble), 'LineWidth', 1.5);
hold on
stairs(out4.state_trace.time_s, double(out4.state_trace.is_bubble), 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Bubble Flag');
title('Static-Hold vs Tracking-Greedy: Bubble Flag');
legend({'static\_hold','tracking\_greedy'}, 'Location', 'best');
ylim([-0.1 1.1]);
grid on
fig_paths.bubble_flag_png = fullfile(out_dir, ['plot_r4c_bubble_flag_' stamp '.png']);
saveas(fig2, fig_paths.bubble_flag_png);
close(fig2);

% 3) summary bar chart
fig3 = figure('Visible', 'off');
metric_vals = [ ...
    out3.result.bubble_metrics.bubble_time_s, out4.result.bubble_metrics.bubble_time_s; ...
    out3.result.bubble_metrics.max_bubble_depth, out4.result.bubble_metrics.max_bubble_depth; ...
    out3.result.custody_metrics.loc_total_time_s, out4.result.custody_metrics.loc_total_time_s; ...
    out3.result.cost_metrics.resource_score, out4.result.cost_metrics.resource_score; ...
    out3.result.cost_metrics.switch_count, out4.result.cost_metrics.switch_count];

bar(metric_vals);
set(gca, 'XTickLabel', {'bubble\_time','max\_depth','loc\_time','resource','switch'});
legend({'static\_hold','tracking\_greedy'}, 'Location', 'best');
title('Static-Hold vs Tracking-Greedy: Summary Metrics');
grid on
fig_paths.summary_bar_png = fullfile(out_dir, ['plot_r4c_summary_bar_' stamp '.png']);
saveas(fig3, fig_paths.summary_bar_png);
close(fig3);
end
