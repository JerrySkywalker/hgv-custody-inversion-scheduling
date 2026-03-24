function fig = plot_stage10D_margin_analysis(summary_table, eig_table, mode_table, out_png_path)
%PLOT_STAGE10D_MARGIN_ANALYSIS
% Plot truth / zero-mode / bcirc-min comparison and margin bounds.

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1280 880]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    lambda_full = summary_table.lambda_full_eff;
    lambda_zero = summary_table.lambda_zero_mode;
    lambda_bcirc = summary_table.lambda_min_bcirc;
    eps2 = summary_table.eps_sb_2;

    % ------------------------------------------------------------
    % Panel 1: three key minima
    % ------------------------------------------------------------
    nexttile;
    vals = [lambda_full, lambda_zero, lambda_bcirc];
    bar(1:3, vals, 'FaceColor', [0.25 0.55 0.85]);
    xticks(1:3);
    xticklabels({'truth full', 'zero mode', 'bcirc min'});
    ylabel('minimum eigenvalue');
    title('Three key spectral quantities');
    grid on;

    % ------------------------------------------------------------
    % Panel 2: bound intervals
    % ------------------------------------------------------------
    nexttile;
    hold on;
    % truth marker
    plot(1, lambda_full, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8);

    % zero-mode interval
    plot([2 2], [summary_table.zero_lb, summary_table.zero_ub], '-', 'LineWidth', 2, ...
        'Color', [0.2 0.6 0.2]);
    plot(2, lambda_zero, 's', 'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

    % bcirc interval
    plot([3 3], [summary_table.bcirc_lb, summary_table.bcirc_ub], '-', 'LineWidth', 2, ...
        'Color', [0.85 0.3 0.3]);
    plot(3, lambda_bcirc, 'd', 'MarkerFaceColor', [0.85 0.3 0.3], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

    hold off;
    xlim([0.5 3.5]);
    xticks([1 2 3]);
    xticklabels({'truth', 'zero\pm\epsilon', 'bcirc\pm\epsilon'});
    ylabel('eigenvalue / interval');
    title(sprintf('Bounds with \\epsilon_{SB}=%.3g', eps2));
    grid on;

    % ------------------------------------------------------------
    % Panel 3: truth eigs vs zero-mode eigs
    % ------------------------------------------------------------
    nexttile;
    plot(eig_table.eig_index, eig_table.eig_truth_full, '-o', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.2 0.45 0.85]);
    hold on;
    plot(eig_table.eig_index, eig_table.eig_zero_mode, '--s', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.85 0.3 0.3]);
    hold off;
    xlabel('Eigenvalue order');
    ylabel('Eigenvalue');
    title('Truth full vs zero-mode spectrum');
    legend({'truth full', 'zero mode'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: mode minimum spectrum
    % ------------------------------------------------------------
    nexttile;
    plot(mode_table.mode_index, mode_table.lambda_min, '-o', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.65 0.35 0.8]);
    hold on;
    yline(lambda_zero, '--', 'LineWidth', 1.2, 'Color', [0.2 0.6 0.2]);
    yline(lambda_full, ':', 'LineWidth', 1.2, 'Color', [0.2 0.2 0.2]);
    hold off;
    xlabel('Mode index');
    ylabel('\lambda_{min}(A_k)');
    title('Mode minimum spectrum');
    legend({'mode min', 'zero mode', 'truth full'}, 'Location', 'best');
    grid on;

    title(tl, 'Stage10.D symmetry-breaking and margin analysis');

    if nargin >= 4 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end