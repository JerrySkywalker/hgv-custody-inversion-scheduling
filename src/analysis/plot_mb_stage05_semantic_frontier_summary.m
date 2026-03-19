function fig = plot_mb_stage05_semantic_frontier_summary(summary_table, h_km)
%PLOT_MB_STAGE05_SEMANTIC_FRONTIER_SUMMARY Plot the inclination-wise Stage05-semantic frontier summary.

fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic Frontier', 'Position', [160 160 1100 700]);

yyaxis left;
plot(summary_table.i_deg, summary_table.frontier_Ns, '-o', 'LineWidth', 2.5, 'MarkerSize', 10);
ylabel('minimum feasible N_s');

valid_frontier = summary_table.frontier_Ns(isfinite(summary_table.frontier_Ns));
if isempty(valid_frontier)
    ylim([0 1]);
else
    ylim([max(0, min(valid_frontier) - 10), max(valid_frontier) + 10]);
end

yyaxis right;
plot(summary_table.i_deg, summary_table.frontier_D_G_min, '-s', 'LineWidth', 2.5, 'MarkerSize', 9);
ylabel('D_G^{min} of frontier point');

hold on;
for idx = 1:height(summary_table)
    if isfinite(summary_table.frontier_Ns(idx))
        yyaxis left;
        text(summary_table.i_deg(idx) + 0.3, summary_table.frontier_Ns(idx) + 1.0, ...
            sprintf('(P=%g,T=%g)', summary_table.frontier_P(idx), summary_table.frontier_T(idx)), ...
            'FontSize', 11, 'Color', [0.1 0.1 0.1]);
    end
end

xlabel('inclination i (deg)');
title(sprintf('MB Control (Stage05 Semantics): inclination-wise frontier summary at h = %.0f km', h_km));
grid on;
box on;
set(gca, 'FontSize', 13);
end
