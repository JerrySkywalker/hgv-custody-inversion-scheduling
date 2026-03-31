function fig = plot_custody_summary_bars(custodyT, custodyC, out_png)
%PLOT_CUSTODY_SUMMARY_BARS  Compare T and C custody summary metrics.

vals = [
    custodyT.q_worst, custodyC.q_worst;
    custodyT.outage_ratio, custodyC.outage_ratio;
    custodyT.longest_outage_steps, custodyC.longest_outage_steps
    ];

fig = figure('Visible', 'off');
bar(vals);
set(gca, 'XTickLabel', {'q_worst','outage_ratio','longest_outage'});
legend({'T','C'}, 'Location', 'best')
title('Chapter 5 Phase 5 Custody Summary')
grid on

if nargin >= 3 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
