function fig = plot_custody_summary_bars_three(custodyT, custodyC, custodyCK, out_png)
%PLOT_CUSTODY_SUMMARY_BARS_THREE  Compare T / C / CK-min custody summary metrics.

vals = [
    custodyT.q_worst, custodyC.q_worst, custodyCK.q_worst;
    custodyT.outage_ratio, custodyC.outage_ratio, custodyCK.outage_ratio;
    custodyT.longest_outage_steps, custodyC.longest_outage_steps, custodyCK.longest_outage_steps
    ];

fig = figure('Visible', 'off');
bar(vals);
set(gca, 'XTickLabel', {'q_worst','outage_ratio','longest_outage'});
legend({'T','C','CK-min'}, 'Location', 'best')
title('Chapter 5 Phase 6 Custody Summary')
grid on

if nargin >= 4 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
