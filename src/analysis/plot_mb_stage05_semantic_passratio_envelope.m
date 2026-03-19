function fig = plot_mb_stage05_semantic_passratio_envelope(envelope_table, h_km)
%PLOT_MB_STAGE05_SEMANTIC_PASSRATIO_ENVELOPE Plot the Stage05-semantic pass-ratio envelope under MB outputs.

i_list = unique(envelope_table.i_deg, 'sorted');
fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic PassRatio', 'Position', [120 120 1100 700]);
hold on;

if isempty(envelope_table)
    ax = axes(fig);
    axis(ax, 'off');
    text(ax, 0.5, 0.55, 'No feasible point found within current search domain', ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 16);
    text(ax, 0.5, 0.42, sprintf('Search domain summary unavailable at h = %.0f km', h_km), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', [0.25 0.25 0.25]);
    title(ax, sprintf('MB Control (Stage05 Semantics): pass-ratio envelope versus N_s at h = %.0f km', h_km));
    return;
end

cmap = lines(numel(i_list));
for idx = 1:numel(i_list)
    i_deg = i_list(idx);
    Ti = envelope_table(envelope_table.i_deg == i_deg, :);
    Ti = sortrows(Ti, 'Ns');
    plot(Ti.Ns, Ti.max_pass_ratio, '-o', ...
        'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
        'DisplayName', sprintf('i=%g deg', i_deg));
end

xlabel('total satellites N_s');
ylabel('max pass ratio under fixed i');
title(sprintf('MB Control (Stage05 Semantics): pass-ratio envelope versus N_s at h = %.0f km', h_km));
legend('Location', 'eastoutside');
grid on;
box on;
ylim([0 1.05]);
set(gca, 'FontSize', 13);

if ~any(envelope_table.max_pass_ratio >= 1 - 1e-12)
    text(0.02, 0.96, 'No feasible point found within current search domain', ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'Color', [0.25 0.25 0.25], 'VerticalAlignment', 'top');
end
end
