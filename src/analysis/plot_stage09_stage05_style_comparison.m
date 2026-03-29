function fig_files = plot_stage09_stage05_style_comparison(cmp, ~, ~, cfg09)
%PLOT_STAGE09_STAGE05_STYLE_COMPARISON
% Export Stage05-vs-Stage09 DG-only comparison figures into Stage09 output folders.

    if nargin < 4 || isempty(cfg09)
        cfg09 = default_params();
    end

    cfg09 = stage09_prepare_cfg(cfg09);
    cfg09.project_stage = 'stage09_plot_stage05_dg_only_comparison';
    cfg09 = configure_stage_output_paths(cfg09);
    ensure_dir(cfg09.paths.figs);
    ensure_dir(cfg09.paths.tables);

    timestamp = local_pick_cmp_field(cmp, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'));
    run_tag = char(local_pick_cmp_field(cmp, 'run_tag', string(cfg09.stage09.run_tag)));

    fig_files = struct();
    fig_files.diag_scatter = local_plot_diag_scatter(cmp, cfg09, run_tag, timestamp);
    fig_files.frontier = local_plot_frontier(cmp, cfg09, run_tag, timestamp);
    fig_files.heatmap_minNs_diff = local_plot_heatmap_diff(cmp, cfg09, run_tag, timestamp);
    fig_files.passratio_profile = local_plot_passratio_profile(cmp, cfg09, run_tag, timestamp);
    fig_files.mismatch_map = local_plot_mismatch_map(cmp, cfg09, run_tag, timestamp);

    figure_index_table = table( ...
        ["diag_scatter_dg_only"; ...
         "frontier_dg_only"; ...
         "heatmap_minNs_diff_dg_only"; ...
         "passratio_profile_dg_only"; ...
         "mismatch_map_dg_only"], ...
        string({ ...
            fig_files.diag_scatter; ...
            fig_files.frontier; ...
            fig_files.heatmap_minNs_diff; ...
            fig_files.passratio_profile; ...
            fig_files.mismatch_map}), ...
        'VariableNames', {'figure_name','figure_path'});

    figure_index_csv = fullfile(cfg09.paths.tables, ...
        sprintf('stage09_stage05_dg_only_figure_index_%s_%s.csv', run_tag, timestamp));
    writetable(figure_index_table, figure_index_csv);

    fig_files.figure_index_csv = figure_index_csv;
end


function fig_file = local_plot_diag_scatter(cmp, cfg09, run_tag, timestamp)

    T05feas = cmp.stage05_feasible_table;
    T09all = cmp.stage09_table;
    T09feas = cmp.stage09_feasible_table;

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);
    hold on;
    grid(gca, 'on');
    box on;

    if ~isempty(T09all)
        scatter(T09all.Ns, T09all.DG_rob, 28, ...
            'Marker', 'x', ...
            'MarkerEdgeColor', [0.75 0.75 0.75], ...
            'DisplayName', 'Stage09 all scan');
    end

    if ~isempty(T09feas)
        scatter(T09feas.Ns, T09feas.DG_rob, 50, ...
            'filled', ...
            'MarkerFaceColor', [0.00 0.45 0.74], ...
            'MarkerFaceAlpha', 0.75, ...
            'DisplayName', 'Stage09 DG-only feasible');
    end

    if ~isempty(T05feas)
        scatter(T05feas.Ns, T05feas.D_G_min, 54, ...
            'Marker', 's', ...
            'LineWidth', 1.2, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', 'none', ...
            'DisplayName', 'Stage05 feasible');
    end

    yline(cfg09.stage09.require_DG_min, '--', ...
        sprintf('DG threshold = %.3g', cfg09.stage09.require_DG_min), ...
        'Color', [0.4 0.4 0.4], ...
        'HandleVisibility', 'off');
    xlabel('total satellites N_s');
    ylabel('D_G');
    title('Stage05 vs Stage09 (DG-only): scatter comparison');
    legend('Location', 'best');

    fig_file = fullfile(cfg09.paths.figs, ...
        sprintf('stage09_vs_stage05_diag_scatter_dg_only_%s_%s.png', run_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 220);
    close(fig);
end


function fig_file = local_plot_frontier(cmp, cfg09, run_tag, timestamp)

    Tfront = cmp.frontier_compare_table;

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 540]);
    hold on;
    grid(gca, 'on');
    box on;

    plot(Tfront.i_deg, Tfront.Ns_min_stage05, '-s', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 7, ...
        'Color', [0.10 0.10 0.10], ...
        'DisplayName', 'Stage05');
    plot(Tfront.i_deg, Tfront.Ns_min_stage09, '--o', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 7, ...
        'Color', [0.00 0.45 0.74], ...
        'DisplayName', 'Stage09 DG-only');

    idx_equiv = find(Tfront.frontier_equivalent_alt_flag);
    for k = 1:numel(idx_equiv)
        j = idx_equiv(k);
        txt = sprintf('  (%g,%g) vs (%g,%g)', ...
            Tfront.P_stage05(j), Tfront.T_stage05(j), ...
            Tfront.P_stage09(j), Tfront.T_stage09(j));
        text(Tfront.i_deg(j), Tfront.Ns_min_stage05(j), txt, ...
            'VerticalAlignment', 'bottom', ...
            'Color', [0.50 0.20 0.00]);
    end

    xlabel('inclination i (deg)');
    ylabel('minimum feasible N_s');
    title('Stage05 vs Stage09 (DG-only): frontier comparison');
    legend('Location', 'best');

    fig_file = fullfile(cfg09.paths.figs, ...
        sprintf('stage09_vs_stage05_frontier_dg_only_%s_%s.png', run_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 220);
    close(fig);
end


function fig_file = local_plot_heatmap_diff(cmp, cfg09, run_tag, timestamp)

    Tmap = cmp.heatmap_compare_table;
    i_list = unique(Tmap.i_deg(:)).';
    P_list = unique(Tmap.P(:)).';
    Z = nan(numel(P_list), numel(i_list));

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            idx = Tmap.P == P_list(a) & Tmap.i_deg == i_list(b);
            if any(idx)
                Z(a, b) = Tmap.minNs_diff(find(idx, 1, 'first'));
            end
        end
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 920, 520]);
    imagesc(i_list, P_list, Z);
    set(gca, 'YDir', 'normal');
    colormap(local_diverging_colormap());
    cb = colorbar;
    ylabel(cb, 'Stage09 - Stage05 min feasible N_s');
    xlabel('inclination i (deg)');
    ylabel('P');
    title('Stage05 vs Stage09 (DG-only): (i,P) min-N_s difference');
    grid(gca, 'on');

    finite_z = Z(isfinite(Z));
    if isempty(finite_z)
        clim([-1 1]);
    else
        lim = max(1, max(abs(finite_z)));
        clim([-lim lim]);
    end

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            if isnan(Z(a, b))
                text(i_list(b), P_list(a), 'X', ...
                    'HorizontalAlignment', 'center', ...
                    'Color', [0.2 0.2 0.2], ...
                    'FontWeight', 'bold');
            else
                text(i_list(b), P_list(a), sprintf('%g', Z(a, b)), ...
                    'HorizontalAlignment', 'center', ...
                    'Color', 'k', ...
                    'FontWeight', 'bold');
            end
        end
    end

    fig_file = fullfile(cfg09.paths.figs, ...
        sprintf('stage09_vs_stage05_heatmap_minNs_diff_dg_only_%s_%s.png', run_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 220);
    close(fig);
end


function fig_file = local_plot_passratio_profile(cmp, cfg09, run_tag, timestamp)

    Tprof = cmp.passratio_profile_compare_table;
    i_list = unique(Tprof.i_deg(:)).';
    nI = max(numel(i_list), 1);
    nCol = min(3, nI);
    nRow = ceil(nI / nCol);

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1200, max(420, 280*nRow)]);
    tl = tiledlayout(nRow, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');

    for k = 1:numel(i_list)
        ax = nexttile(tl);
        hold(ax, 'on');
        grid(ax, 'on');
        box(ax, 'on');

        sub = Tprof(Tprof.i_deg == i_list(k), :);
        plot(ax, sub.Ns, sub.pass_stage05, '-s', ...
            'LineWidth', 1.5, ...
            'MarkerSize', 5, ...
            'Color', [0.10 0.10 0.10], ...
            'DisplayName', 'Stage05');
        plot(ax, sub.Ns, sub.pass_stage09, '--o', ...
            'LineWidth', 1.5, ...
            'MarkerSize', 5, ...
            'Color', [0.00 0.45 0.74], ...
            'DisplayName', 'Stage09 DG-only');
        yline(ax, cfg09.stage09.require_pass_ratio, '--', ...
            'Color', [0.4 0.4 0.4], ...
            'HandleVisibility', 'off');
        ylim(ax, [0 1.05]);
        title(ax, sprintf('i = %.0f deg', i_list(k)));
        xlabel(ax, 'N_s');
        ylabel(ax, 'max pass ratio');

        if k == 1
            legend(ax, 'Location', 'southoutside');
        end
    end

    title(tl, 'Stage05 vs Stage09 (DG-only): pass-ratio profiles');

    fig_file = fullfile(cfg09.paths.figs, ...
        sprintf('stage09_vs_stage05_passratio_profile_dg_only_%s_%s.png', run_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 220);
    close(fig);
end


function fig_file = local_plot_mismatch_map(cmp, cfg09, run_tag, timestamp)

    Tmain = cmp.main_compare_table;
    Tfront = cmp.frontier_compare_table;
    Theat = cmp.heatmap_compare_table;

    [i_list, P_list, feas_map, heat_map] = local_build_mismatch_heatmaps(Tmain, Theat);
    frontier_status = local_build_frontier_status(Tfront);

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1280, 420]);
    tl = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile(tl);
    imagesc(ax1, i_list, P_list, feas_map);
    set(ax1, 'YDir', 'normal');
    title(ax1, 'Feasible label mismatch count');
    xlabel(ax1, 'i (deg)');
    ylabel(ax1, 'P');
    colorbar(ax1);
    grid(ax1, 'on');
    local_annotate_matrix(ax1, i_list, P_list, feas_map);

    ax2 = nexttile(tl);
    imagesc(ax2, Tfront.i_deg(:).', 1, frontier_status(:).');
    set(ax2, 'YDir', 'normal');
    title(ax2, 'Frontier status');
    xlabel(ax2, 'i (deg)');
    yticks(ax2, 1);
    yticklabels(ax2, {'frontier'});
    clim(ax2, [0 2]);
    colormap(ax2, [0.85 0.93 0.85; 0.98 0.93 0.72; 0.96 0.79 0.79]);
    grid(ax2, 'on');
    for k = 1:height(Tfront)
        label = "OK";
        if frontier_status(k) == 1
            label = "ALT";
        elseif frontier_status(k) == 2
            label = "X";
        end
        text(ax2, Tfront.i_deg(k), 1, char(label), ...
            'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold');
    end

    ax3 = nexttile(tl);
    imagesc(ax3, i_list, P_list, heat_map);
    set(ax3, 'YDir', 'normal');
    title(ax3, '(i,P) min-N_s mismatch');
    xlabel(ax3, 'i (deg)');
    ylabel(ax3, 'P');
    colorbar(ax3);
    grid(ax3, 'on');
    local_annotate_matrix(ax3, i_list, P_list, heat_map);

    title(tl, 'Stage05 vs Stage09 (DG-only): mismatch map');

    fig_file = fullfile(cfg09.paths.figs, ...
        sprintf('stage09_vs_stage05_mismatch_map_dg_only_%s_%s.png', run_tag, timestamp));
    exportgraphics(fig, fig_file, 'Resolution', 220);
    close(fig);
end


function [i_list, P_list, feas_map, heat_map] = local_build_mismatch_heatmaps(Tmain, Theat)

    i_list = unique([Tmain.i_deg(:); Theat.i_deg(:)]).';
    P_list = unique([Tmain.P(:); Theat.P(:)]).';
    feas_map = zeros(numel(P_list), numel(i_list));
    heat_map = zeros(numel(P_list), numel(i_list));

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            idx_main = Tmain.P == P_list(a) & Tmain.i_deg == i_list(b) & Tmain.row_match & ~Tmain.feas_match;
            feas_map(a, b) = sum(idx_main);

            idx_heat = Theat.P == P_list(a) & Theat.i_deg == i_list(b);
            if any(idx_heat)
                heat_map(a, b) = double(~Theat.heatmap_match_flag(find(idx_heat, 1, 'first')));
            end
        end
    end
end


function status = local_build_frontier_status(Tfront)

    status = zeros(height(Tfront), 1);
    for k = 1:height(Tfront)
        if ~Tfront.frontier_match_flag(k)
            status(k) = 2;
        elseif Tfront.frontier_equivalent_alt_flag(k)
            status(k) = 1;
        end
    end
end


function local_annotate_matrix(ax, i_list, P_list, Z)

    for a = 1:numel(P_list)
        for b = 1:numel(i_list)
            text(ax, i_list(b), P_list(a), sprintf('%g', Z(a, b)), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold');
        end
    end
end


function cmap = local_diverging_colormap()

    n = 128;
    r = [linspace(0.23, 1.00, n).'; linspace(1.00, 0.70, n).'];
    g = [linspace(0.30, 1.00, n).'; linspace(1.00, 0.23, n).'];
    b = [linspace(0.75, 1.00, n).'; linspace(1.00, 0.20, n).'];
    cmap = [r g b];
end


function value = local_pick_cmp_field(S, field_name, default_value)

    if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
        value = S.(field_name);
    else
        value = default_value;
    end
end
