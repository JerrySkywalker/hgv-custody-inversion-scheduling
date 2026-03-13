function fig = plot_stage10C_mode_spectrum(summary_table, mode_table, out_png_path)
%PLOT_STAGE10C_MODE_SPECTRUM
% Plot FFT mode spectrum validation for Stage10.C.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1240 860]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: mode min eigenvalues
    % ------------------------------------------------------------
    nexttile;
    plot(mode_table.mode_index, mode_table.lambda_min, '-o', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.2 0.45 0.85]);
    hold on;
    yline(summary_table.lambda_min_bcirc, '--', 'LineWidth', 1.2, 'Color', [0.85 0.25 0.25]);
    yline(summary_table.lambda_full_eff, ':', 'LineWidth', 1.2, 'Color', [0.2 0.6 0.2]);
    hold off;
    xlabel('Mode index');
    ylabel('Mode min eigenvalue');
    title('Mode-wise min eigenvalues');
    legend({'FFT mode min', 'bcirc full min', 'truth full min'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: mode traces
    % ------------------------------------------------------------
    nexttile;
    bar(mode_table.mode_index, mode_table.trace_mode, 'FaceColor', [0.3 0.7 0.4]);
    xlabel('Mode index');
    ylabel('trace(A_k)');
    title('Mode traces');
    grid on;

    % ------------------------------------------------------------
    % Panel 3: mode fro norms
    % ------------------------------------------------------------
    nexttile;
    bar(mode_table.mode_index, mode_table.fro_mode, 'FaceColor', [0.8 0.55 0.2]);
    xlabel('Mode index');
    ylabel('||A_k||_F');
    title('Mode Frobenius norms');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: summary text
    % ------------------------------------------------------------
    nexttile;
    txt = {
        sprintf('lambda_full_eff         = %.6g', summary_table.lambda_full_eff)
        sprintf('lambda_min_bcirc        = %.6g', summary_table.lambda_min_bcirc)
        sprintf('lambda_min_fft          = %.6g', summary_table.lambda_min_fft)
        sprintf('fft_consistency_abs_err = %.6g', summary_table.fft_consistency_abs_err)
        sprintf('fft_consistency_rel_err = %.6g', summary_table.fft_consistency_rel_err)
        sprintf('mode_argmin             = %d', summary_table.mode_argmin)
        sprintf('lambda_zero_mode        = %.6g', summary_table.lambda_zero_mode)
        sprintf('bcirc_vs_truth_abs_gap  = %.6g', summary_table.bcirc_vs_truth_abs_gap)
        sprintf('bcirc_vs_truth_rel_gap  = %.6g', summary_table.bcirc_vs_truth_rel_gap)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('FFT validation summary');

    title(tl, 'Stage10.C FFT spectral validation');

    if nargin >= 3 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end