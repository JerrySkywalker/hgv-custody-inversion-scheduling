function fig = plot_stage10E_screening_benchmark(scan_table, confusion_table, summary_table, out_png_path)
%PLOT_STAGE10E_SCREENING_BENCHMARK
% Plot screening benchmark results.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1280 900]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: truth vs zero vs bcirc
    % ------------------------------------------------------------
    nexttile;
    plot(scan_table.lambda_truth, '-o', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.15 0.15 0.15]);
    hold on;
    plot(scan_table.lambda_zero, '--s', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.2 0.6 0.2]);
    plot(scan_table.lambda_bcirc, ':d', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.85 0.25 0.25]);
    hold off;
    xlabel('Grid sample index');
    ylabel('Screening value');
    title('Truth vs zero-mode vs bcirc-min');
    legend({'truth', 'zero-mode', 'bcirc-min'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: eps_sb
    % ------------------------------------------------------------
    nexttile;
    bar(scan_table.eps_sb_2, 'FaceColor', [0.35 0.55 0.85]);
    xlabel('Grid sample index');
    ylabel('\epsilon_{SB}^{(0)}');
    title('Zero-mode embedded symmetry-breaking norm');
    grid on;

    % ------------------------------------------------------------
    % Panel 3: confusion summary
    % ------------------------------------------------------------
    nexttile;
    vals = [confusion_table.TP, confusion_table.FP, confusion_table.FN, confusion_table.TN];
    b = bar(categorical(confusion_table.method), vals, 'grouped');
    b(1).FaceColor = [0.2 0.6 0.2];
    b(2).FaceColor = [0.85 0.3 0.3];
    b(3).FaceColor = [0.9 0.7 0.2];
    b(4).FaceColor = [0.55 0.55 0.55];
    ylabel('Count');
    title('Confusion counts vs truth');
    legend({'TP','FP','FN','TN'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: summary text
    % ------------------------------------------------------------
    nexttile;
    txt = {
        sprintf('N_total               = %d', summary_table.N_total)
        sprintf('N_truth_pass          = %d', summary_table.N_truth_pass)
        sprintf('N_truth_fail          = %d', summary_table.N_truth_fail)
        sprintf('mean |truth-zero|     = %.6g', summary_table.mean_gap_truth_zero)
        sprintf('mean |truth-bcirc|    = %.6g', summary_table.mean_gap_truth_bcirc)
        sprintf('mean eps_sb_2         = %.6g', summary_table.mean_eps_sb_2)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('Benchmark summary');

    title(tl, 'Stage10.E screening benchmark');

    if nargin >= 4 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end