function fig = plot_stage10F_master_figure(core, master_table, screening_table, out_png_path)
%PLOT_STAGE10F_MASTER_FIGURE
% Generate a compact thesis-ready Stage10 master figure.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1320 940]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: representative spectrum comparison
    % ------------------------------------------------------------
    nexttile;
    vals = [master_table.lambda_zero_mode, master_table.lambda_min_bcirc, core.outD.summary_table.lambda_full_eff];
    bar(1:3, vals, 'FaceColor', [0.25 0.55 0.85]);
    xticks(1:3);
    xticklabels({'zero mode', 'bcirc min', 'truth full'});
    ylabel('Minimum eigenvalue');
    title('Representative spectral comparison');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: mode minimum spectrum
    % ------------------------------------------------------------
    nexttile;
    plot(core.outC.mode_table.mode_index, core.outC.mode_table.lambda_min, '-o', ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0.65 0.35 0.8]);
    hold on;
    yline(master_table.lambda_zero_mode, '--', 'LineWidth', 1.2, 'Color', [0.2 0.6 0.2]);
    yline(core.outD.summary_table.lambda_full_eff, ':', 'LineWidth', 1.2, 'Color', [0.15 0.15 0.15]);
    hold off;
    xlabel('Mode index');
    ylabel('\lambda_{min}(A_k)');
    title('Legal bcirc mode minimum spectrum');
    legend({'mode min','zero mode','truth full'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 3: refined screening confusion
    % ------------------------------------------------------------
    nexttile;
    vals = [ ...
        screening_table.TP_accept_after_refine, screening_table.FP_accept_after_refine, screening_table.FN_accept_after_refine, screening_table.TN_accept_after_refine; ...
        screening_table.TP_safe_only, screening_table.FP_safe_only, screening_table.FN_safe_only, screening_table.TN_safe_only];
    b = bar(categorical({'accept\_after\_refine','safe\_only'}), vals, 'grouped');
    b(1).FaceColor = [0.2 0.6 0.2];
    b(2).FaceColor = [0.85 0.3 0.3];
    b(3).FaceColor = [0.9 0.7 0.2];
    b(4).FaceColor = [0.55 0.55 0.55];
    ylabel('Count');
    title('Refined screening benchmark');
    legend({'TP','FP','FN','TN'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: summary text
    % ------------------------------------------------------------
    nexttile;
    txt = {
        sprintf('Representative sample:')
        sprintf('  h=%.0f km, i=%.0f deg, P=%d, T=%d, Ns=%d', ...
            master_table.h_km, master_table.i_deg, master_table.P, master_table.T, master_table.Ns)
        sprintf('  n_active_plane = %d', master_table.n_active_plane)
        sprintf('  active_ratio   = %.3f', master_table.active_ratio)
        sprintf('  top1/top2/top3 = %.3f / %.3f / %.3f', ...
            master_table.top1_trace_share, master_table.top2_trace_share, master_table.top3_trace_share)
        sprintf(' ')
        sprintf('Legalization:')
        sprintf('  mirror gap before/after = %.3g / %.3g', ...
            master_table.mirror_gap_before, master_table.mirror_gap_after)
        sprintf('  lambda proto/legal      = %.3g / %.3g', ...
            master_table.lambda_min_proto_bcirc, master_table.lambda_min_legal_bcirc)
        sprintf('  FFT consistency abs err = %.3g', master_table.fft_consistency_abs_err)
        sprintf(' ')
        sprintf('Margins:')
        sprintf('  eps_sb_2 / eps_sb_fro   = %.3g / %.3g', master_table.eps_sb_2, master_table.eps_sb_fro)
        sprintf('  gap truth-zero          = %.3g', master_table.gap_full_zero)
        sprintf('  gap truth-bcirc         = %.3g', master_table.gap_full_bcirc)
        sprintf(' ')
        sprintf('Refined screening grid:')
        sprintf('  N_total / N_pass / N_fail = %d / %d / %d', ...
            screening_table.N_total, screening_table.N_truth_pass, screening_table.N_truth_fail)
        sprintf('  reject / warn / safe      = %d / %d / %d', ...
            screening_table.N_reject, screening_table.N_warn, screening_table.N_safe)
        sprintf('  accept_after_refine TP/FN = %d / %d', ...
            screening_table.TP_accept_after_refine, screening_table.FN_accept_after_refine)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 10.5);
    title('Stage10 master summary');

    title(tl, 'Stage10 final evidence pack');

    if nargin >= 4 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 220);
    end
end