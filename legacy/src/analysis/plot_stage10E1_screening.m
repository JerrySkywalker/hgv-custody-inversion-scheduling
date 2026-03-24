function fig = plot_stage10E1_screening(scan_table_e1, confusion_table, label_count_table, summary_table, out_png_path)
%PLOT_STAGE10E1_SCREENING
% Plot refined screening rule benchmark.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1280 920]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: truth / zero / bcirc
    % ------------------------------------------------------------
    nexttile;
    plot(scan_table_e1.lambda_truth, '-o', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.15 0.15 0.15]);
    hold on;
    plot(scan_table_e1.lambda_zero, '--s', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.2 0.6 0.2]);
    plot(scan_table_e1.lambda_bcirc, ':d', 'LineWidth', 1.2, 'MarkerSize', 4, 'Color', [0.85 0.25 0.25]);
    hold off;
    xlabel('Grid sample index');
    ylabel('Screening value');
    title('Truth vs zero-mode vs bcirc-min');
    legend({'truth', 'zero-mode', 'bcirc-min'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: stage labels
    % ------------------------------------------------------------
    nexttile;
    bar(categorical(label_count_table.stage_label), label_count_table.count, 'FaceColor', [0.35 0.55 0.85]);
    ylabel('Count');
    title('Refined screening labels');
    grid on;

    % ------------------------------------------------------------
    % Panel 3: confusion views
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
        sprintf('N_reject              = %d', summary_table.N_reject)
        sprintf('N_warn                = %d', summary_table.N_warn)
        sprintf('N_safe                = %d', summary_table.N_safe)
        sprintf('truth-pass -> warn    = %d', summary_table.N_truth_pass_warn)
        sprintf('truth-pass -> safe    = %d', summary_table.N_truth_pass_safe)
        sprintf('truth-fail -> warn    = %d', summary_table.N_truth_fail_warn)
        sprintf('truth-fail -> safe    = %d', summary_table.N_truth_fail_safe)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('Refined rule summary');

    title(tl, 'Stage10.E.1 refined screening rule benchmark');

    if nargin >= 5 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end