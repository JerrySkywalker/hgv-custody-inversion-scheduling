function fig = plot_custody_phi_timeline(time, phiT, phiC, out_png)
%PLOT_CUSTODY_PHI_TIMELINE  Compare T and C phi series over time.

fig = figure('Visible', 'off');
plot(time, phiT, 'LineWidth', 1.2); hold on
plot(time, phiC, 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('\phi')
title('Chapter 5 Phase 5 Custody \phi Timeline')
legend({'T: tracking-dynamic', 'C: custody-singleloop'}, 'Location', 'best')
grid on

if nargin >= 4 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
