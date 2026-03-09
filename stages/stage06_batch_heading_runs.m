function out = stage06_batch_heading_runs(cfg0)
    %STAGE06_BATCH_HEADING_RUNS
    % Stage06.6 batch runner + batch analysis.
    %
    % Reads heading families from cfg.stage06.batch and runs:
    %   Stage06.1 -> Stage06.2b -> Stage06.3 -> Stage06.4 -> Stage06.5
    % for each heading-offset set.
    %
    % In addition, this script generates batch-level comparison artifacts:
    %   1) frontier overview figure (slope-graph style):
    %        nominal / small / full / ...
    %   2) Delta-Ns heatmap:
    %        family x inclination, relative to nominal
    %   3) batch frontier tables
    %   4) batch summary tables
    %
    % Usage:
    %   out = stage06_batch_heading_runs();
    %   out = stage06_batch_heading_runs(cfg0);
    
        startup();
    
        if nargin < 1 || isempty(cfg0)
            cfg0 = default_params();
        end
        cfg0 = stage06_prepare_cfg(cfg0);
    
        assert(isfield(cfg0.stage06, 'batch') && cfg0.stage06.batch.enable, ...
            'cfg.stage06.batch.enable must be true.');
    
        run_tags = cfg0.stage06.batch.run_tags;
        heading_sets = cfg0.stage06.batch.heading_offset_sets;
    
        assert(numel(run_tags) == numel(heading_sets), ...
            'run_tags and heading_offset_sets must have the same length.');
    
        ensure_dir(cfg0.paths.logs);
        ensure_dir(cfg0.paths.cache);
        ensure_dir(cfg0.paths.tables);
        ensure_dir(cfg0.paths.figs);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg0.paths.logs, ...
            sprintf('stage06_batch_heading_runs_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open batch log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.6 batch started.');
    
        nRun = numel(run_tags);
        runs = cell(nRun,1);
        summary_rows = {};
    
        % ============================================================
        % Run each heading family
        % ============================================================
        for k = 1:nRun
            cfg = default_params();
    
            cfg.stage06.active_heading_set_name = 'custom';
            cfg.stage06.active_heading_offsets_custom_deg = heading_sets{k};
            cfg.stage06.run_tag = char(run_tags{k});
    
            cfg = stage06_prepare_cfg(cfg);
    
            log_msg(log_fid, 'INFO', ...
                'Run %d/%d | run_tag=%s | heading_offsets=%s', ...
                k, nRun, cfg.stage06.run_tag, mat2str(cfg.stage06.active_heading_offsets_deg));
    
            run_out = struct();
            run_out.run_tag = cfg.stage06.run_tag;
            run_out.heading_offsets_deg = cfg.stage06.active_heading_offsets_deg;
    
            if cfg.stage06.batch.run_scope
                run_out.scope = stage06_define_heading_scope(cfg);
            end
    
            if cfg.stage06.batch.run_family
                run_out.family_demo = stage06_build_heading_family_physical_demo(cfg);
            end
    
            if cfg.stage06.batch.run_search
                run_out.search = stage06_heading_walker_search(cfg);
            end
    
            if cfg.stage06.batch.run_compare
                run_out.compare = stage06_compare_with_stage05(cfg);
            end
    
            if cfg.stage06.batch.run_plot
                run_out.plot = stage06_plot_heading_results(cfg);
            end
    
            runs{k} = run_out;
    
            % --------------------------------------------------------
            % collect batch summary row
            % --------------------------------------------------------
            if isfield(run_out, 'compare')
                cmp = run_out.compare;
                gs = cmp.global_summary;
                as = cmp.auto_summary;
    
                summary_rows(end+1,:) = { ...
                    string(cfg.stage06.run_tag), ...
                    mat2str(cfg.stage06.active_heading_offsets_deg), ...
                    numel(cfg.stage06.active_heading_offsets_deg), ...
                    cfg.stage06.expected_family_size, ...
                    gs.n_stage06_feasible(1), ...
                    as.n_feasible_mismatch, ...
                    as.n_frontier_shift, ...
                    as.feasible_same_ratio, ...
                    as.frontier_same_ratio, ...
                    gs.best_Ns_stage06(1), ...
                    gs.delta_best_Ns(1) ...
                    }; %#ok<AGROW>
            else
                summary_rows(end+1,:) = { ...
                    string(cfg.stage06.run_tag), ...
                    mat2str(cfg.stage06.active_heading_offsets_deg), ...
                    numel(cfg.stage06.active_heading_offsets_deg), ...
                    cfg.stage06.expected_family_size, ...
                    NaN, NaN, NaN, NaN, NaN, NaN, NaN ...
                    }; %#ok<AGROW>
            end
        end
    
        batch_summary = cell2table(summary_rows, 'VariableNames', { ...
            'run_tag', ...
            'heading_offsets_deg', ...
            'n_heading_offsets', ...
            'expected_family_size', ...
            'n_stage06_feasible', ...
            'n_feasible_mismatch', ...
            'n_frontier_shift', ...
            'feasible_same_ratio', ...
            'frontier_same_ratio', ...
            'best_Ns_stage06', ...
            'delta_best_Ns'});
    
        % ============================================================
        % Build batch-level frontier / delta tables
        % ============================================================
        [frontier_overview, deltaNs_by_i, nominal_frontier] = ...
            local_build_batch_frontier_tables(runs, run_tags);
    
        % ============================================================
        % Save batch tables
        % ============================================================
        summary_csv = fullfile(cfg0.paths.tables, ...
            sprintf('stage06_batch_summary_%s.csv', timestamp));
        writetable(batch_summary, summary_csv);
    
        frontier_csv = fullfile(cfg0.paths.tables, ...
            sprintf('stage06_batch_frontier_overview_%s.csv', timestamp));
        writetable(frontier_overview, frontier_csv);
    
        delta_csv = fullfile(cfg0.paths.tables, ...
            sprintf('stage06_batch_deltaNs_by_i_%s.csv', timestamp));
        writetable(deltaNs_by_i, delta_csv);
    
        nominal_csv = fullfile(cfg0.paths.tables, ...
            sprintf('stage06_batch_nominal_frontier_%s.csv', timestamp));
        writetable(nominal_frontier, nominal_csv);
    
        % ============================================================
        % Make batch analysis figures
        % ============================================================
        batch_figs = local_make_batch_analysis_figures( ...
            cfg0, frontier_overview, deltaNs_by_i, run_tags, timestamp, log_fid);
    
        % ============================================================
        % Save output
        % ============================================================
        out = struct();
        out.runs = runs;
        out.batch_summary = batch_summary;
        out.frontier_overview = frontier_overview;
        out.deltaNs_by_i = deltaNs_by_i;
        out.nominal_frontier = nominal_frontier;
        out.batch_figs = batch_figs;
        out.log_file = log_file;
        out.summary_csv = summary_csv;
        out.frontier_csv = frontier_csv;
        out.delta_csv = delta_csv;
        out.nominal_csv = nominal_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg0.paths.cache, ...
            sprintf('stage06_batch_heading_runs_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
        out.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Batch summary saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Batch frontier overview saved to: %s', frontier_csv);
        log_msg(log_fid, 'INFO', 'Batch delta-Ns table saved to: %s', delta_csv);
        log_msg(log_fid, 'INFO', 'Stage06.6 batch finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.6 Batch Summary ==========\n');
        disp(batch_summary);
        fprintf('Summary CSV   : %s\n', summary_csv);
        fprintf('Frontier CSV  : %s\n', frontier_csv);
        fprintf('DeltaNs CSV   : %s\n', delta_csv);
        fprintf('Batch Cache   : %s\n', cache_file);
        fprintf('=============================================\n');
    end
    
    
    % =========================================================================
    % Build batch frontier tables
    % =========================================================================
    function [frontier_overview, deltaNs_by_i, nominal_frontier] = ...
        local_build_batch_frontier_tables(runs, run_tags)
    
        nRun = numel(runs);
        assert(nRun >= 1, 'No runs available for batch frontier analysis.');
    
        % Use the first run as reference to extract nominal frontier
        assert(isfield(runs{1}, 'compare') && isfield(runs{1}.compare, 'frontier_compare_by_i'), ...
            'First run is missing compare.frontier_compare_by_i.');
    
        ref_frontier = runs{1}.compare.frontier_compare_by_i;
        i_list = ref_frontier.i_deg(:);
    
        nominal_frontier = table( ...
            i_list, ...
            ref_frontier.min_feasible_Ns_stage05, ...
            ref_frontier.best_P_stage05, ...
            ref_frontier.best_T_stage05, ...
            ref_frontier.D_G_min_stage05, ...
            ref_frontier.pass_ratio_stage05, ...
            'VariableNames', { ...
            'i_deg', ...
            'Ns_nominal', ...
            'best_P_nominal', ...
            'best_T_nominal', ...
            'D_G_min_nominal', ...
            'pass_ratio_nominal'});
    
        frontier_overview = nominal_frontier(:, {'i_deg','Ns_nominal'});
        deltaNs_by_i = table(i_list, 'VariableNames', {'i_deg'});
    
        for k = 1:nRun
            run_tag = matlab.lang.makeValidName(char(run_tags{k}));
            assert(isfield(runs{k}, 'compare') && isfield(runs{k}.compare, 'frontier_compare_by_i'), ...
                'Run %d is missing compare.frontier_compare_by_i.', k);
    
            fTbl = runs{k}.compare.frontier_compare_by_i;
    
            assert(isequal(fTbl.i_deg(:), i_list), ...
                'Run %s frontier i_deg does not match reference.', char(run_tags{k}));
    
            frontier_overview.(sprintf('Ns_%s', run_tag)) = fTbl.min_feasible_Ns_stage06;
            frontier_overview.(sprintf('deltaNs_%s', run_tag)) = ...
                fTbl.min_feasible_Ns_stage06 - fTbl.min_feasible_Ns_stage05;
    
            deltaNs_by_i.(sprintf('deltaNs_%s', run_tag)) = ...
                fTbl.min_feasible_Ns_stage06 - fTbl.min_feasible_Ns_stage05;
        end
    end
    
    
    % =========================================================================
    % Make batch analysis figures
    % =========================================================================
    function batch_figs = local_make_batch_analysis_figures( ...
        cfg0, frontier_overview, deltaNs_by_i, run_tags, timestamp, log_fid)
    
        fig_dir = cfg0.paths.figs;
        ensure_dir(fig_dir);
    
        batch_figs = struct();
    
        % ------------------------------------------------------------
        % Fig A: Frontier slope-graph style overview
        % ------------------------------------------------------------
        figA = figure('Name', 'Stage06 Batch Frontier Slope Graph', 'Color', 'w');
        hold on; grid on; box on;
    
        % x-axis is family category, not inclination
        x_levels = 1:(1 + numel(run_tags));
        x_labels = ['nominal', string(run_tags(:)')];
    
        i_deg = frontier_overview.i_deg(:);
        nI = numel(i_deg);
    
        % Build Y matrix: rows = inclination, cols = family category
        Y = nan(nI, numel(x_levels));
        Y(:,1) = frontier_overview.Ns_nominal;
    
        for k = 1:numel(run_tags)
            run_tag = matlab.lang.makeValidName(char(run_tags{k}));
            Y(:,1+k) = frontier_overview.(sprintf('Ns_%s', run_tag));
        end
    
        C = parula(nI);
    
        % plot one line per inclination
        for ii = 1:nI
            plot(x_levels, Y(ii,:), '-o', ...
                'LineWidth', 1.6, ...
                'MarkerSize', 7, ...
                'Color', C(ii,:), ...
                'DisplayName', sprintf('i=%g^\\circ', i_deg(ii)));
        end
    
        % annotate only changed values to reduce clutter
        for ii = 1:nI
            y_nom = Y(ii,1);
            for k = 2:numel(x_levels)
                yk = Y(ii,k);
                if isfinite(yk) && isfinite(y_nom) && abs(yk - y_nom) > 0
                    text(x_levels(k) + 0.03, yk, sprintf('+%g', yk - y_nom), ...
                        'FontSize', 9, ...
                        'Color', C(ii,:), ...
                        'VerticalAlignment', 'bottom');
                end
            end
        end
    
        xlim([0.8, numel(x_levels) + 0.2]);
        set(gca, 'XTick', x_levels, 'XTickLabel', x_labels);
        xlabel('Heading-family scenario');
        ylabel('Minimum feasible N_s');
        title('Batch frontier overview (slope-graph style)');
        legend('Location', 'eastoutside');
    
        fA_png = fullfile(fig_dir, sprintf('stage06_batch_frontier_slope_%s.png', timestamp));
        fA_fig = fullfile(fig_dir, sprintf('stage06_batch_frontier_slope_%s.fig', timestamp));
        saveas(figA, fA_png);
        savefig(figA, fA_fig);
    
        % ------------------------------------------------------------
        % Fig B: Delta-Ns heatmap (family x inclination)
        % ------------------------------------------------------------
        figB = figure('Name', 'Stage06 Batch DeltaNs Heatmap', 'Color', 'w');
    
        i_deg = deltaNs_by_i.i_deg(:);
        nI = numel(i_deg);
        nRun = numel(run_tags);
    
        M = nan(nRun, nI);
        for k = 1:nRun
            run_tag = matlab.lang.makeValidName(char(run_tags{k}));
            M(k,:) = deltaNs_by_i.(sprintf('deltaNs_%s', run_tag)).';
        end
    
        imagesc(i_deg, 1:nRun, M);
        set(gca, 'YDir', 'normal');
        xlabel('Inclination i (deg)');
        ylabel('Heading-family scenario');
        title('\DeltaN_s relative to nominal');
        set(gca, 'YTick', 1:nRun, 'YTickLabel', string(run_tags(:)));
        cb = colorbar;
        cb.Label.String = '\DeltaN_s';
    
        colormap(parula);
        grid on; box on;
    
        % annotate cells
        for r = 1:nRun
            for c = 1:nI
                val = M(r,c);
                if isfinite(val)
                    text(i_deg(c), r, sprintf('%g', val), ...
                        'HorizontalAlignment', 'center', ...
                        'FontSize', 9, ...
                        'Color', 'k');
                end
            end
        end
    
        fB_png = fullfile(fig_dir, sprintf('stage06_batch_deltaNs_heatmap_%s.png', timestamp));
        fB_fig = fullfile(fig_dir, sprintf('stage06_batch_deltaNs_heatmap_%s.fig', timestamp));
        saveas(figB, fB_png);
        savefig(figB, fB_fig);
    
        batch_figs.frontier_slope_png = fA_png;
        batch_figs.frontier_slope_fig = fA_fig;
        batch_figs.deltaNs_heatmap_png = fB_png;
        batch_figs.deltaNs_heatmap_fig = fB_fig;
    
        log_msg(log_fid, 'INFO', 'Batch frontier slope-graph saved to: %s', fA_png);
        log_msg(log_fid, 'INFO', 'Batch delta-Ns heatmap saved to: %s', fB_png);
    end