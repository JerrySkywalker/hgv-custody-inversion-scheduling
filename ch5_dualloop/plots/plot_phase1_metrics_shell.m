function fig = plot_phase1_metrics_shell(result, out_png)
%PLOT_PHASE1_METRICS_SHELL  Simple shell-stage timeline plot.

t = result.time(:);
phi = result.phi_series(:);
rmse = result.rmse_pos(:);

fig = figure('Visible', 'off');
yyaxis left
plot(t, phi, 'LineWidth', 1.2);
ylabel('phi')

yyaxis right
plot(t, rmse, 'LineWidth', 1.2);
ylabel('RMSE')
xlabel('Time (s)')
title('Chapter 5 Phase 1 Metrics Shell')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
