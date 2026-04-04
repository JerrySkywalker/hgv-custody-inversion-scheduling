function fig_path = plot_ch5r_rmse_proxy_comparison(out3, out4, out5, out_dir, stamp)
%PLOT_CH5R_RMSE_PROXY_COMPARISON
% Plot Fisher-based RMSE proxy curves for R3-real / R4-real / R5-real.

if nargin < 4 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 5 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig = figure('Visible', 'off');
plot(out3.case.t_s, out3.result.rmse_proxy_metrics.series, 'LineWidth', 1.2);
hold on
plot(out4.case.t_s, out4.result.rmse_proxy_metrics.series, 'LineWidth', 1.2);
plot(out5.case.t_s, out5.result.rmse_proxy_metrics.series, 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('RMSE proxy');
title('R3-real vs R4-real vs R5-real: Fisher-based RMSE proxy');
legend({'R3-real static pair','R4-real dynamic pair','R5-real predictive pair'}, 'Location', 'best');
grid on

fig_path = fullfile(out_dir, ['plot_r5c_real_rmse_proxy_' stamp '.png']);
saveas(fig, fig_path);
close(fig);
end
