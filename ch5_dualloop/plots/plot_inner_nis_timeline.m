function fig = plot_inner_nis_timeline(inner, out_png)
%PLOT_INNER_NIS_TIMELINE  Plot NIS and position error timeline.

t = inner.time(:);
nis = inner.nis(:);
pos_err = inner.pos_err_norm(:);

fig = figure('Visible', 'off');
yyaxis left
plot(t, nis, 'LineWidth', 1.2);
ylabel('NIS')

yyaxis right
plot(t, pos_err, 'LineWidth', 1.2);
ylabel('Position Error Norm')
xlabel('Time (s)')
title('Chapter 5 Phase 2 Inner Loop NIS Timeline')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
