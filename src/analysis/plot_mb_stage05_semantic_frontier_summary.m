function fig = plot_mb_stage05_semantic_frontier_summary(summary_table, h_km)
%PLOT_MB_STAGE05_SEMANTIC_FRONTIER_SUMMARY Plot the inclination-wise Stage05-semantic frontier summary.

fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic Frontier', 'Position', [160 160 1100 700]);

valid_frontier = summary_table.frontier_Ns(isfinite(summary_table.frontier_Ns));
if isempty(valid_frontier)
    ax = axes(fig);
    axis(ax, 'off');
    x_span = local_i_span_string(summary_table);
    text(ax, 0.5, 0.58, 'No feasible point found within current search domain', ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 16);
    text(ax, 0.5, 0.44, sprintf('Search domain: h = %.0f km, i = %s', h_km, x_span), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', [0.25 0.25 0.25]);
    title(ax, sprintf('MB Control (Stage05 Semantics): inclination-wise frontier summary at h = %.0f km', h_km));
    return;
end

yyaxis left;
plot(summary_table.i_deg, summary_table.frontier_Ns, '-o', 'LineWidth', 2.5, 'MarkerSize', 10);
ylabel('minimum feasible N_s');

ylim([max(0, min(valid_frontier) - 10), max(valid_frontier) + 10]);

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

function span_text = local_i_span_string(summary_table)
if isempty(summary_table) || ~ismember('i_deg', summary_table.Properties.VariableNames)
    span_text = 'unknown';
    return;
end
i_vals = summary_table.i_deg(:);
i_vals = i_vals(isfinite(i_vals));
if isempty(i_vals)
    span_text = 'unknown';
else
    span_text = sprintf('[%.0f, %.0f] deg', min(i_vals), max(i_vals));
end
end
