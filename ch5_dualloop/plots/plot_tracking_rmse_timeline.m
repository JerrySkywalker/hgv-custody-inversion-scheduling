function fig = plot_tracking_rmse_timeline(result, out_png)
%PLOT_TRACKING_RMSE_TIMELINE  Plot tracking RMSE timeline.

t = result.time(:);
rmse = result.rmse_pos(:);

fig = figure('Visible', 'off');
plot(t, rmse, 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('RMSE')
title('Chapter 5 Phase 3 Tracking RMSE Timeline')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
