function fig_paths = plot_tracking_vs_static_summary_real(out3, out4, out_dir, stamp)
%PLOT_TRACKING_VS_STATIC_SUMMARY_REAL  Generate real comparison plots for R4c-real.

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
plot(out3.wininfo.t_s, out3.wininfo.lambda_min, 'LineWidth', 1.5);
hold on
plot(out4.wininfo.t_s, out4.wininfo.lambda_min, 'LineWidth', 1.5);
yline(out3.bubble.gamma_req, '--', 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('\lambda_{min}(J_W)');
title('R3-real vs R4-real: \lambda_{min}(J_W) Timeline');
legend({'R3-real static pair','R4-real dynamic pair','\gamma_{req}'}, 'Location', 'best');
grid on
fig_paths.lambda_timeline_png = fullfile(out_dir, ['plot_r4c_real_lambda_timeline_' stamp '.png']);
saveas(fig1, fig_paths.lambda_timeline_png);
close(fig1);

% 2) bubble flag comparison
fig2 = figure('Visible', 'off');
stairs(out3.bubble.t_s, double(out3.bubble.is_bubble), 'LineWidth', 1.5);
hold on
stairs(out4.bubble.t_s, double(out4.bubble.is_bubble), 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Bubble Flag');
title('R3-real vs R4-real: Bubble Flag');
legend({'R3-real static pair','R4-real dynamic pair'}, 'Location', 'best');
ylim([-0.1 1.1]);
grid on
fig_paths.bubble_flag_png = fullfile(out_dir, ['plot_r4c_real_bubble_flag_' stamp '.png']);
saveas(fig2, fig_paths.bubble_flag_png);
close(fig2);

% 3) pair index trace comparison
fig3 = figure('Visible', 'off');
idx3 = local_pair_code_trace(out3.selection_trace);
idx4 = local_pair_code_trace(out4.selection_trace);
stairs(out3.case.t_s, idx3, 'LineWidth', 1.5);
hold on
stairs(out4.case.t_s, idx4, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Pair Code');
title('R3-real vs R4-real: Pair Selection Trace');
legend({'R3-real static pair','R4-real dynamic pair'}, 'Location', 'best');
grid on
fig_paths.pair_trace_png = fullfile(out_dir, ['plot_r4c_real_pair_trace_' stamp '.png']);
saveas(fig3, fig_paths.pair_trace_png);
close(fig3);

% 4) summary bars
fig4 = figure('Visible', 'off');
metric_vals = [ ...
    out3.result.bubble_time_s, out4.result.bubble_time_s; ...
    out3.result.max_bubble_depth, out4.result.max_bubble_depth; ...
    out3.result.switch_count, out4.result.switch_count; ...
    out3.result.resource_score, out4.result.resource_score];

bar(metric_vals);
set(gca, 'XTickLabel', {'bubble\_time','max\_depth','switch','resource'});
legend({'R3-real static pair','R4-real dynamic pair'}, 'Location', 'best');
title('R3-real vs R4-real: Summary Metrics');
grid on
fig_paths.summary_bar_png = fullfile(out_dir, ['plot_r4c_real_summary_bar_' stamp '.png']);
saveas(fig4, fig_paths.summary_bar_png);
close(fig4);
end

function codes = local_pair_code_trace(selection_trace)
N = numel(selection_trace);
codes = nan(N,1);

for k = 1:N
    pair = selection_trace{k}.pair;
    if isempty(pair)
        codes(k) = -1;
    else
        codes(k) = pair(1) * 1000 + pair(2);
    end
end
end
