function fig_path = plot_bubble_timeline(state_trace, out_dir, stamp)
%PLOT_BUBBLE_TIMELINE  Plot lambda_min timeline against gamma_req.

if nargin < 2 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 3 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig = figure('Visible', 'off');
plot(state_trace.time_s, state_trace.lambda_min, 'LineWidth', 1.5);
hold on
yline(state_trace.gamma_req, '--', 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('\lambda_{min}(Y_W)');
title('Bubble Timeline');
grid on

fig_path = fullfile(out_dir, ['plot_bubble_timeline_' stamp '.png']);
saveas(fig, fig_path);
close(fig);
end
