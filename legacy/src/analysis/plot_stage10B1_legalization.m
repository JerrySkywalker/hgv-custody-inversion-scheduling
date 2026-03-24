function fig = plot_stage10B1_legalization(summary_table, firstcol_before_table, firstcol_after_table, mode_table, out_png_path)
%PLOT_STAGE10B1_LEGALIZATION
% Plot before/after legalization diagnostics.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1240 860]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: first-column trace before/after
    % ------------------------------------------------------------
    nexttile;
    plot(firstcol_before_table.lag_index, firstcol_before_table.trace_block, '-o', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.8 0.25 0.25]);
    hold on;
    plot(firstcol_after_table.lag_index, firstcol_after_table.trace_block, '--s', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.2 0.55 0.2]);
    hold off;
    xlabel('Lag index');
    ylabel('trace block');
    title('First-column trace: before vs after legalization');
    legend({'prototype', 'legalized'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: mode min eig before/after
    % ------------------------------------------------------------
    nexttile;
    plot(mode_table.mode_index, mode_table.lambda_mode_min_before, '-o', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.8 0.25 0.25]);
    hold on;
    plot(mode_table.mode_index, mode_table.lambda_mode_min_after, '--s', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.2 0.55 0.2]);
    yline(0, ':k', 'LineWidth', 1.0);
    hold off;
    xlabel('Mode index');
    ylabel('min eig of mode block');
    title('Mode PSD legalization');
    legend({'before', 'after', 'zero'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 3: first-column block min eigenvalues before/after
    % ------------------------------------------------------------
    nexttile;
    plot(firstcol_before_table.lag_index, firstcol_before_table.lambda_min_block, '-o', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.1 0.4 0.85]);
    hold on;
    plot(firstcol_after_table.lag_index, firstcol_after_table.lambda_min_block, '--d', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.85 0.45 0.1]);
    hold off;
    xlabel('Lag index');
    ylabel('min eig of lag block');
    title('First-column block spectra');
    legend({'prototype', 'legalized'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: summary text
    % ------------------------------------------------------------
    nexttile;
    txt = {
        sprintf('lambda_full_eff              = %.6g', summary_table.lambda_full_eff)
        sprintf('lambda_min_proto_bcirc       = %.6g', summary_table.lambda_min_proto_bcirc)
        sprintf('lambda_min_legal_bcirc       = %.6g', summary_table.lambda_min_legal_bcirc)
        sprintf('mirror_gap_before            = %.6g', summary_table.mirror_gap_before)
        sprintf('mirror_gap_after             = %.6g', summary_table.mirror_gap_after)
        sprintf('self_err_proto_fro           = %.6g', summary_table.self_err_proto_fro)
        sprintf('self_err_legal_fro           = %.6g', summary_table.self_err_legal_fro)
        sprintf('legal_vs_proto_fro           = %.6g', summary_table.legal_vs_proto_fro)
        sprintf('legal_vs_truth_reduced_fro   = %.6g', summary_table.legal_vs_truth_reduced_fro)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('Legalization summary');

    title(tl, 'Stage10.B.1 bcirc legalization');

    if nargin >= 5 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end