function fig = plot_phase2p5_truth_summary(truth, out_png)
%PLOT_PHASE2P5_TRUTH_SUMMARY  Plot basic truth summary for phase 2.5A.

t = truth.t(:);

fig = figure('Visible', 'off');

subplot(2,1,1)
if isfield(truth, 'h_km')
    plot(t, truth.h_km, 'LineWidth', 1.2);
    ylabel('Altitude (km)')
else
    plot(t, nan(size(t)));
    ylabel('Altitude (km)')
end
title('Chapter 5 Phase 2.5A Truth Summary')
grid on

subplot(2,1,2)
if isfield(truth, 'vx') && isfield(truth, 'vy') && isfield(truth, 'vz')
    speed = sqrt(truth.vx.^2 + truth.vy.^2 + truth.vz.^2);
    plot(t, speed, 'LineWidth', 1.2);
    ylabel('Speed')
else
    plot(t, nan(size(t)));
    ylabel('Speed')
end
xlabel('Time (s)')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
