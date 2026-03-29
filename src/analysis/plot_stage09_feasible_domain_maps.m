function fig_files = plot_stage09_feasible_domain_maps(pdata, cfg, timestamp)
%PLOT_STAGE09_FEASIBLE_DOMAIN_MAPS Plot Stage09 paper-oriented domain maps.
%
% Outputs:
%   fig_files.minNs_hi
%   fig_files.fail_hi_refPT
%   fig_files.feasible_PT

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end
    cfg = stage09_prepare_cfg(cfg);
    ensure_dir(cfg.paths.figs);

    S = build_stage09_paper_plot_tables(pdata.out9_4, pdata.out9_5, cfg);

    % ------------------------------------------------------------
    % Figure 1: h-i plane minimum feasible Ns projection
    % ------------------------------------------------------------
    f1 = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);
    hold on;
    grid(gca, 'on');
    box on;

    Thi = S.hi_minNs_table;
    infeas = Thi(~Thi.has_feasible, :);
    feas = Thi(Thi.has_feasible, :);

    if ~isempty(infeas)
        scatter(infeas.i_deg, infeas.h_km, 40, ...
            'Marker', 'x', ...
            'MarkerEdgeColor', [0.3 0.3 0.3], ...
            'DisplayName', 'No joint-feasible design');
    end
    if ~isempty(feas)
        scatter(feas.i_deg, feas.h_km, 90, feas.Ns_min_feasible, 'filled', ...
            'DisplayName', 'Min joint-feasible N_s');
        cb = colorbar;
        ylabel(cb, 'minimum feasible N_s');

        do_label = height(feas) <= 30;
        if do_label
            for k = 1:height(feas)
                xoff = 0.4 * (-1)^(k);
                yoff = 6 + 3 * mod(k, 3);
                txt = sprintf('%d [%d,%d]', round(feas.Ns_min_feasible(k)), ...
                    round(feas.P_at_minNs(k)), round(feas.T_at_minNs(k)));
                text(feas.i_deg(k) + xoff, feas.h_km(k) + yoff, txt, 'FontSize', 8);
            end
        end
    end

    xlabel('Inclination i [deg]');
    ylabel('Altitude h [km]');
    title('Stage09 minimum feasible N_s projected on h-i plane');
    legend('Location', 'best');

    fig_files.minNs_hi = fullfile(cfg.paths.figs, ...
        sprintf('stage09_minNs_hi_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f1, fig_files.minNs_hi, 'Resolution', 200);
    close(f1);

    % ------------------------------------------------------------
    % Figure 2: fail partition in h-i plane at representative PT pair(s)
    % ------------------------------------------------------------
    f2 = figure('Visible', 'off', 'Color', 'w', ...
        'Position', local_fail_figure_position(S.PT_ref_table));

    TrefAll = S.fail_hi_refPT_table;
    PT_ref_table = S.PT_ref_table;

    if isempty(TrefAll) || isempty(PT_ref_table)
        text(0.5, 0.5, 'Stage09 fail partition unavailable', 'HorizontalAlignment', 'center');
        axis off;
    else
        all_tags = unique(string(TrefAll.dominant_fail_tag));
        cmap = lines(max(numel(all_tags), 1));

        nPanel = height(PT_ref_table);
        nCol = ceil(sqrt(nPanel));
        nRow = ceil(nPanel / nCol);
        tl = tiledlayout(nRow, nCol, 'Padding', 'compact', 'TileSpacing', 'compact');

        for p = 1:nPanel
            ax = nexttile(tl);
            hold(ax, 'on');
            grid(ax, 'on');
            box(ax, 'on');

            Tref = TrefAll(TrefAll.P == PT_ref_table.P(p) & TrefAll.T == PT_ref_table.T(p), :);
            for k = 1:numel(all_tags)
                mask = string(Tref.dominant_fail_tag) == all_tags(k);
                if ~any(mask)
                    continue;
                end

                if p == 1
                    display_name = char(all_tags(k));
                else
                    display_name = '';
                end

                scatter(ax, Tref.i_deg(mask), Tref.h_km(mask), 54, ...
                    'filled', ...
                    'MarkerFaceColor', cmap(k, :), ...
                    'DisplayName', display_name);
            end

            xlabel(ax, 'Inclination i [deg]');
            ylabel(ax, 'Altitude h [km]');
            title(ax, sprintf('P=%d, T=%d', PT_ref_table.P(p), PT_ref_table.T(p)));

            if p == 1
                legend(ax, 'Location', 'bestoutside');
            end
        end

        title(tl, sprintf('Stage09 fail partition in h-i plane (%s)', strrep(cfg.stage09.refPT_mode, '_', '\_')));
    end

    fig_files.fail_hi_refPT = fullfile(cfg.paths.figs, ...
        sprintf('stage09_fail_partition_hi_refPT_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f2, fig_files.fail_hi_refPT, 'Resolution', 200);
    close(f2);

    % ------------------------------------------------------------
    % Figure 3: feasible domain in P-T plane
    % ------------------------------------------------------------
    f3 = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 920, 540]);
    hold on;
    grid(gca, 'on');
    box on;

    Tpt = S.pt_minNs_table;
    cval = Tpt.feasible_ratio_hi;
    cval(~isfinite(cval)) = 0;

    scatter(Tpt.P, Tpt.T, 90, cval, 'filled', 'DisplayName', 'feasible ratio over h-i');
    cb = colorbar;
    ylabel(cb, 'joint-feasible ratio over h-i');

    Tinfeas = Tpt(~Tpt.has_feasible, :);
    if ~isempty(Tinfeas)
        scatter(Tinfeas.P, Tinfeas.T, 50, ...
            'Marker', 'x', ...
            'MarkerEdgeColor', 'k', ...
            'DisplayName', 'No joint-feasible h-i');
    end

    if ~isempty(S.theta_min_table)
        PTmin = unique(S.theta_min_table(:, {'P', 'T'}), 'rows');
        scatter(PTmin.P, PTmin.T, 140, ...
            'Marker', 'o', ...
            'LineWidth', 1.5, ...
            'MarkerEdgeColor', 'k', 'DisplayName', '\Theta_{Nmin}');
    end

    xlabel('Number of planes P');
    ylabel('Satellites per plane T');
    title('Stage09 feasible domain in P-T plane');
    legend('Location', 'best');

    fig_files.feasible_PT = fullfile(cfg.paths.figs, ...
        sprintf('stage09_feasible_PT_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f3, fig_files.feasible_PT, 'Resolution', 200);
    close(f3);
end


function pos = local_fail_figure_position(PT_ref_table)

    nPanel = max(height(PT_ref_table), 1);
    nCol = ceil(sqrt(nPanel));
    nRow = ceil(nPanel / nCol);
    pos = [100, 100, 420 * nCol, 320 * nRow];
end
