function fig = plot_mb_stage05_semantic_DG_envelope(envelope_table, h_km)
%PLOT_MB_STAGE05_SEMANTIC_DG_ENVELOPE Plot the Stage05-semantic D_G envelope under MB outputs.

i_list = unique(envelope_table.i_deg, 'sorted');
fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic DG', 'Position', [140 140 1100 700]);
hold on;

cmap = lines(numel(i_list));
for idx = 1:numel(i_list)
    i_deg = i_list(idx);
    Ti = envelope_table(envelope_table.i_deg == i_deg, :);
    Ti = sortrows(Ti, 'Ns');
    plot(Ti.Ns, Ti.max_D_G_min, '-s', ...
        'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 7, ...
        'DisplayName', sprintf('i=%g deg', i_deg));
end

xlabel('total satellites N_s');
ylabel('max D_G^{min} under fixed i');
title(sprintf('MB Control (Stage05 Semantics): D_G^{min} envelope versus N_s at h = %.0f km', h_km));
legend('Location', 'eastoutside');
grid on;
box on;
set(gca, 'FontSize', 13);
end
