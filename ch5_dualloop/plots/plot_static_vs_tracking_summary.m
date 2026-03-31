function fig = plot_static_vs_tracking_summary(resultS, resultT, out_png)
%PLOT_STATIC_VS_TRACKING_SUMMARY  Compare S vs T in one figure.

t = resultS.time(:);

fig = figure('Visible', 'off');

subplot(2,1,1)
plot(t, resultS.tracking_sat_count, 'LineWidth', 1.2); hold on
plot(t, resultT.tracking_sat_count, 'LineWidth', 1.2);
ylabel('Tracking Sat Count')
title('Chapter 5 Phase 4: Static-hold vs Tracking-dynamic')
legend({'S: static-hold','T: tracking-dynamic'}, 'Location', 'best')
grid on

subplot(2,1,2)
plot(t, resultS.rmse_pos, 'LineWidth', 1.2); hold on
plot(t, resultT.rmse_pos, 'LineWidth', 1.2);
ylabel('RMSE')
xlabel('Time (s)')
legend({'S: static-hold','T: tracking-dynamic'}, 'Location', 'best')
grid on

if nargin >= 3 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
