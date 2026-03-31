function fig = plot_outerA_quadrant_stats(stats, out_png)
%PLOT_OUTERA_QUADRANT_STATS  Plot outerA state/quadrant ratios.

vals1 = [stats.safe_ratio, stats.warn_ratio, stats.trigger_ratio];
vals2 = [stats.q1_ratio, stats.q2_ratio, stats.q3_ratio, stats.q4_ratio];

fig = figure('Visible', 'off');

subplot(2,1,1)
bar(vals1)
set(gca, 'XTickLabel', {'safe','warn','trigger'})
ylabel('ratio')
title('OuterA Risk State Ratios')
grid on

subplot(2,1,2)
bar(vals2)
set(gca, 'XTickLabel', {'Q1','Q2','Q3','Q4'})
ylabel('ratio')
title('OuterA Risk Quadrant Ratios')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
