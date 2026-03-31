function fig = plot_custody_phi_timeline_three(time, phiT, phiC, phiCK, out_png)
%PLOT_CUSTODY_PHI_TIMELINE_THREE  Plot T / C / CK-min phi series.

fig = figure('Visible', 'off');
plot(time, phiT, 'LineWidth', 1.2); hold on
plot(time, phiC, 'LineWidth', 1.2);
plot(time, phiCK, 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('\phi')
title('Chapter 5 Phase 6 Custody \phi Timeline')
legend({'T','C','CK-min'}, 'Location', 'best')
grid on

if nargin >= 5 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
