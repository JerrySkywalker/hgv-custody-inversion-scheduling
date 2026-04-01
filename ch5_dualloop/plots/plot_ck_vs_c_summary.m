function fig = plot_ck_vs_c_summary(time, trackingC, trackingCK, out_png)
%PLOT_CK_VS_C_SUMMARY  Compare C and CK on tracking count and RMSE.

fig = figure('Visible', 'off');

subplot(2,1,1)
plot(time, trackingC.tracking_sat_count, 'LineWidth', 1.2); hold on
plot(time, trackingCK.tracking_sat_count, 'LineWidth', 1.2);
ylabel('Tracking Sat Count')
title('Phase 7A: C vs CK')
legend({'C','CK'}, 'Location', 'best')
grid on

subplot(2,1,2)
plot(time, trackingC.rmse_pos, 'LineWidth', 1.2); hold on
plot(time, trackingCK.rmse_pos, 'LineWidth', 1.2);
ylabel('RMSE')
xlabel('Time (s)')
legend({'C','CK'}, 'Location', 'best')
grid on

if nargin >= 4 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
