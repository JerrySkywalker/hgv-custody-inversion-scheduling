function fig = plot_stage10A_plane_structure(summary_table, plane_table, lag_table, out_png_path, cfg)
%PLOT_STAGE10A_PLANE_STRUCTURE
% Plot truth-side plane structure diagnostics for Stage10.A.

    if nargin < 5
        cfg = default_params();
    end
    cfg = stage10A_prepare_cfg(cfg);

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 820]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % ------------------------------------------------------------
    % Panel 1: per-plane trace
    % ------------------------------------------------------------
    nexttile;
    b = bar(plane_table.plane_id, plane_table.trace_Wp);
    b.FaceColor = [0.2 0.45 0.8];
    hold on;
    idx_act = find(plane_table.active_flag);
    if ~isempty(idx_act)
        scatter(plane_table.plane_id(idx_act), plane_table.trace_Wp(idx_act), 45, 'filled', ...
            'MarkerFaceColor', [0.9 0.2 0.2], 'MarkerEdgeColor', 'k');
    end
    hold off;
    xlabel('Plane ID');
    ylabel('trace(W_p)');
    title(sprintf('Per-plane truth trace (n_{active}=%d / %d)', ...
        summary_table.n_active_plane, summary_table.P));
    grid on;

    % ------------------------------------------------------------
    % Panel 2: measurement counts
    % ------------------------------------------------------------
    nexttile;
    b = bar(plane_table.plane_id, plane_table.measurement_count);
    b.FaceColor = [0.25 0.7 0.35];
    xlabel('Plane ID');
    ylabel('Visible obs count');
    title(sprintf('Per-plane visible observations (total=%d)', ...
        summary_table.measurement_count_total));
    grid on;

    % ------------------------------------------------------------
    % Panel 3: anchor-relative lag profile
    % ------------------------------------------------------------
    nexttile;
    plot(lag_table.lag_index, lag_table.lag_trace_ref, '-o', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.15 0.15 0.7]);
    hold on;
    plot(lag_table.lag_index, lag_table.lag_trace_active_mean, '--s', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.85 0.25 0.25]);
    hold off;
    xlabel('Relative lag');
    ylabel('trace block');
    title(sprintf('Lag profile (anchor plane = %d)', summary_table.anchor_plane));
    legend({'anchor-relative truth', 'active-anchor mean'}, 'Location', 'best');
    grid on;

    % ------------------------------------------------------------
    % Panel 4: normalized concentration summary
    % ------------------------------------------------------------
    nexttile;
    txt = {
        sprintf('active ratio              = %.3f', summary_table.active_ratio)
        sprintf('entropy trace (norm)      = %.3f', summary_table.entropy_trace_norm)
        sprintf('entropy meas  (norm)      = %.3f', summary_table.entropy_meas_norm)
        sprintf('cv trace                  = %.3f', summary_table.cv_trace)
        sprintf('cv meas                   = %.3f', summary_table.cv_meas)
        sprintf('top1 trace share          = %.3f', summary_table.top1_trace_share)
        sprintf('top2 trace share          = %.3f', summary_table.top2_trace_share)
        sprintf('top3 trace share          = %.3f', summary_table.top3_trace_share)
        sprintf('lag profile gap L1        = %.3f', summary_table.lag_profile_gap_l1)
        sprintf('lag profile gap L2        = %.3f', summary_table.lag_profile_gap_l2)
        sprintf('lambda_full = [%.3f, %.3f, %.3f]', ...
            summary_table.lambda1_full, summary_table.lambda2_full, summary_table.lambda3_full)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('Structure summary');

    title(tl, 'Stage10.A Truth-side structure diagnostics');

    if nargin >= 4 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end