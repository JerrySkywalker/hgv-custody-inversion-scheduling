function fig = plot_dualloop_evidence_timeline(time, phi_series, outerA, out_png)
%PLOT_DUALLOOP_EVIDENCE_TIMELINE  Plot phi and outerA evidence on one figure.

fig = figure('Visible', 'off');

subplot(4,1,1)
plot(time, phi_series, 'LineWidth', 1.2)
ylabel('\phi')
title('Phase 6A OuterA Evidence Timeline')
grid on

subplot(4,1,2)
plot(time, outerA.mr_hat, 'LineWidth', 1.2); hold on
plot(time, outerA.mr_tilde, 'LineWidth', 1.2);
ylabel('M_R')
legend({'mr\_hat','mr\_tilde'}, 'Location', 'best')
grid on

subplot(4,1,3)
plot(time, outerA.omega_max, 'LineWidth', 1.2)
ylabel('\omega_{max}')
grid on

subplot(4,1,4)
stairs(time, outerA.risk_state, 'LineWidth', 1.2)
xlabel('Time (s)')
ylabel('state')
yticks([0 1 2])
yticklabels({'safe','warn','trigger'})
grid on

if nargin >= 4 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
