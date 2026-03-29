function fig_files = plot_stage09_stage05_aligned_diagnostics(out9_4, cfg, timestamp)
%PLOT_STAGE09_STAGE05_ALIGNED_DIAGNOSTICS Export Stage05-style diagnostics for Stage09.
%
% Outputs:
%   fig_files.fig_diag_scatter
%   fig_files.fig_diag_frontier
%   fig_files.fig_diag_heatmap_minNs_iP
%   fig_files.fig_diag_heatmap_bestDG_iP
%   fig_files.fig_diag_passratio_profile

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end
    cfg = stage09_prepare_cfg(cfg);
    ensure_dir(cfg.paths.figs);

    S = build_stage09_stage05_aligned_tables(out9_4, cfg);
    h_tag = local_h_tag(S.h_slice_km);
    run_tag = char(cfg.stage09.run_tag);

    fig_files = struct();
    fig_files.fig_diag_scatter = local_plot_diag_scatter(S, cfg, timestamp, run_tag, h_tag);
    fig_files.fig_diag_frontier = local_plot_diag_frontier(S, cfg, timestamp, run_tag, h_tag);
    fig_files.fig_diag_heatmap_minNs_iP = local_plot_heatmap_minNs(S, cfg, timestamp, run_tag, h_tag);
    fig_files.fig_diag_heatmap_bestDG_iP = local_plot_heatmap_bestDG(S, cfg, timestamp, run_tag, h_tag);
    fig_files.fig_diag_passratio_profile = local_plot_passratio_profile(S, cfg, timestamp, run_tag, h_tag);
end


function fig_file = local_plot_diag_scatter(S, cfg, timestamp, run_tag, h_tag)

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);
    hold on;
    grid(gca, 'on');
    box on;

    Tall = S.slice_table;
    Tfeas = S.slice_stage05_feasible_table;

    if isempty(Tall)
        text(0.5, 0.5, 'Empty h-slice', 'HorizontalAlignment', 'center');
        axis off;
    else
        scatter(Tall.Ns, Tall.DG_rob, 28, ...
            'Marker', 'x', ...
            'MarkerEdgeColor', [0.75 0.75 0.75], ...
            'DisplayName', 'All scanned');

        if ~isempty(Tfeas)
            scatter(Tfeas.Ns, Tfeas.DG_rob, 64, Tfeas.i_deg, 'filled', ...
                'MarkerFaceAlpha', 0.85, 'DisplayName', 'Stage05-compatible');
            colormap(parula);
            cb = colorbar;
            ylabel(cb, 'inclination i (deg)');
        end

        if ~isempty(S.best_stage05_compat_overall)
            best = S.best_stage05_compat_overall(1, :);
            plot(best.Ns, best.DG_rob, 'kp', 'MarkerSize', 16, 'MarkerFaceColor', 'y', ...
                'DisplayName', 'best Stage05-compatible');
            text(best.Ns, best.DG_rob, ...
                sprintf('  best: i=%.0f, P=%d, T=%d', best.i_deg, best.P, best.T), ...
                'VerticalAlignment', 'bottom');
        end

        yline(cfg.stage09.require_DG_min, '--', 'Stage05 DG threshold', ...
            'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
        xlabel('total satellites N_s');
        ylabel('DG_{rob}');
        title(sprintf('Stage09 diagnostic scatter at h=%.0f km', S.h_slice_km));
        legend('Location', 'best');
    end

    fig_file = fullfile(cfg.paths.figs, ...
        sprintf('stage09_diag_scatter_%s_%s_%s.png', run_tag, h_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 200);
    close(fig);
end


function fig_file = local_plot_diag_frontier(S, cfg, timestamp, run_tag, h_tag)

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 540]);
    Tfront = S.frontier_stage05_table;

    if isempty(Tfront)
        text(0.5, 0.5, 'No Stage05-compatible frontier available', ...
            'HorizontalAlignment', 'center');
        axis off;
    else
        yyaxis left;
        plot(Tfront.i_deg, Tfront.Ns, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
        xlabel('inclination i (deg)');
        ylabel('minimum feasible N_s');
        grid(gca, 'on');
        box on;
        hold on;

        yyaxis right;
        plot(Tfront.i_deg, Tfront.DG_rob, '-s', 'LineWidth', 1.8, 'MarkerSize', 7);
        ylabel('DG_{rob} of frontier point');
        title(sprintf('Stage09 diagnostic frontier at h=%.0f km', S.h_slice_km));

        for k = 1:height(Tfront)
            yyaxis left;
            text(Tfront.i_deg(k), Tfront.Ns(k), sprintf(' (P=%d,T=%d)', Tfront.P(k), Tfront.T(k)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
        end
    end

    fig_file = fullfile(cfg.paths.figs, ...
        sprintf('stage09_diag_frontier_%s_%s_%s.png', run_tag, h_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 200);
    close(fig);
end


function fig_file = local_plot_heatmap_minNs(S, cfg, timestamp, run_tag, h_tag)

    Tmap = S.heatmap_minNs_iP_table;
    i_list = unique(Tmap.i_deg(:)).';
    P_list = unique(Tmap.P(:)).';
    Z = nan(numel(P_list), numel(i_list));

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            idx = Tmap.P == P_list(a) & Tmap.i_deg == i_list(b);
            if any(idx)
                Z(a, b) = Tmap.min_feasible_Ns(find(idx, 1, 'first'));
            end
        end
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 920, 520]);
    imagesc(i_list, P_list, Z);
    set(gca, 'YDir', 'normal');
    xlabel('inclination i (deg)');
    ylabel('P');
    title(sprintf('Stage09 diagnostic min feasible N_s over (i, P) at h=%.0f km', S.h_slice_km));
    colorbar;
    grid(gca, 'on');

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            if isfinite(Z(a, b))
                text(i_list(b), P_list(a), sprintf('%d', round(Z(a, b))), ...
                    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            else
                text(i_list(b), P_list(a), 'X', 'HorizontalAlignment', 'center');
            end
        end
    end

    fig_file = fullfile(cfg.paths.figs, ...
        sprintf('stage09_diag_heatmap_minNs_iP_%s_%s_%s.png', run_tag, h_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 200);
    close(fig);
end


function fig_file = local_plot_heatmap_bestDG(S, cfg, timestamp, run_tag, h_tag)

    Tmap = S.heatmap_bestDG_iP_table;
    i_list = unique(Tmap.i_deg(:)).';
    P_list = unique(Tmap.P(:)).';
    Z = nan(numel(P_list), numel(i_list));

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            idx = Tmap.P == P_list(a) & Tmap.i_deg == i_list(b);
            if any(idx)
                Z(a, b) = Tmap.best_DG_rob(find(idx, 1, 'first'));
            end
        end
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 920, 520]);
    imagesc(i_list, P_list, Z);
    set(gca, 'YDir', 'normal');
    xlabel('inclination i (deg)');
    ylabel('P');
    title(sprintf('Stage09 diagnostic best DG_{rob} over (i, P) at h=%.0f km', S.h_slice_km));
    colorbar;
    grid(gca, 'on');

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            if isfinite(Z(a, b))
                text(i_list(b), P_list(a), sprintf('%.2f', Z(a, b)), ...
                    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            else
                text(i_list(b), P_list(a), 'X', 'HorizontalAlignment', 'center');
            end
        end
    end

    fig_file = fullfile(cfg.paths.figs, ...
        sprintf('stage09_diag_heatmap_bestDG_iP_%s_%s_%s.png', run_tag, h_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 200);
    close(fig);
end


function fig_file = local_plot_passratio_profile(S, cfg, timestamp, run_tag, h_tag)

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);
    hold on;
    grid(gca, 'on');
    box on;

    Tprof = S.passratio_profile_table;
    i_list = unique(Tprof.i_deg(:)).';
    cmap = lines(max(numel(i_list), 1));

    if isempty(Tprof)
        text(0.5, 0.5, 'Empty pass-ratio profile', 'HorizontalAlignment', 'center');
        axis off;
    else
        for k = 1:numel(i_list)
            sub = Tprof(Tprof.i_deg == i_list(k), :);
            if isempty(sub)
                continue;
            end

            plot(sub.Ns, sub.max_pass_ratio, '-o', 'LineWidth', 1.2, 'MarkerSize', 5, ...
                'Color', cmap(k, :), 'DisplayName', sprintf('i=%.0f deg', i_list(k)));

            sub_feas = sub(sub.has_stage05_compat, :);
            if ~isempty(sub_feas)
                scatter(sub_feas.Ns, sub_feas.max_pass_ratio, 48, ...
                    'filled', ...
                    'MarkerFaceColor', cmap(k, :), 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            end
        end

        yline(cfg.stage09.require_pass_ratio, '--', 'Stage05 pass threshold', ...
            'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
        xlabel('total satellites N_s');
        ylabel('max pass ratio under fixed i');
        ylim([0, 1.05]);
        title(sprintf('Stage09 diagnostic pass-ratio profile at h=%.0f km', S.h_slice_km));
        legend('Location', 'eastoutside');
    end

    fig_file = fullfile(cfg.paths.figs, ...
        sprintf('stage09_diag_passratio_profile_%s_%s_%s.png', run_tag, h_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 200);
    close(fig);
end


function tag = local_h_tag(h_km)

    tag = sprintf('h%skm', strrep(num2str(h_km, '%g'), '.', 'p'));
end
