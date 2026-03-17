function outp = stage05_plot_nominal_results(cfg)
    %STAGE05_PLOT_NOMINAL_RESULTS
    % Stage05.3:
    % Post-process and visualize Stage05.2b nominal Walker static search results.
    %
    % Compatible with Stage05.2b cache structure:
    %   out.grid
    %   out.feasible_grid
    %   out.summary
    %   out.cfg
    %
    % Main outputs:
    %   1) best feasible summary table
    %   2) all feasible table (sorted)
    %   3) inclination-wise frontier table
    %   4) figure: feasible Ns-D_G scatter
    %   5) figure: inclination frontier
    %   6) figure: min-Ns feasible heatmap over (i, P)
    %   7) figure: best-D_G heatmap over (i, P)
    %
    % Saved to:
    %   outputs/stage/figs
    %   outputs/stage/tables
    %   outputs/stage/cache
    
        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage05_plot_nominal_results';
        cfg = configure_stage_output_paths(cfg);
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
        ensure_dir(cfg.paths.cache);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage05_plot_nominal_results_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage05.3 started.');
    
        % ============================================================
        % Load latest Stage05 cache
        % ============================================================
        d5 = find_stage_cache_files(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat');
        assert(~isempty(d5), ...
            'No Stage05 cache found. Please run stage05_nominal_walker_search first.');
    
        [~, idx5] = max([d5.datenum]);
        stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
        S5 = load(stage05_file);
    
        assert(isfield(S5, 'out'), 'Invalid Stage05 cache: missing out');
        assert(isfield(S5.out, 'grid'), 'Invalid Stage05 cache: missing out.grid');
    
        out5 = S5.out;
        gridTbl = out5.grid;

        log_msg(log_fid, 'INFO', 'Loaded Stage05 cache: %s', stage05_file);

        % ============================================================
        % Normalize grid fields
        % ============================================================
        gridTbl = local_normalize_grid(gridTbl);

        assert(ismember('i_deg', gridTbl.Properties.VariableNames), 'grid missing i_deg');
        assert(ismember('P', gridTbl.Properties.VariableNames), 'grid missing P');
        assert(ismember('T', gridTbl.Properties.VariableNames), 'grid missing T');
        assert(ismember('Ns', gridTbl.Properties.VariableNames), 'grid missing Ns');
        assert(ismember('D_G_min', gridTbl.Properties.VariableNames), 'grid missing D_G_min');
        assert(ismember('pass_ratio', gridTbl.Properties.VariableNames), 'grid missing pass_ratio');
        assert(ismember('feasible_flag', gridTbl.Properties.VariableNames), 'grid missing feasible_flag');
        assert(ismember('n_case_evaluated', gridTbl.Properties.VariableNames), 'grid missing n_case_evaluated');
        assert(ismember('failed_early', gridTbl.Properties.VariableNames), 'grid missing failed_early');

        if ismember('rank_score', gridTbl.Properties.VariableNames)
            has_rank = true;
        else
            has_rank = false;
            gridTbl.rank_score = nan(height(gridTbl),1);
        end

        feasible_grid = gridTbl(gridTbl.feasible_flag > 0, :);
        feasible_grid = local_sort_feasible_grid(feasible_grid);
    
        i_list = unique(gridTbl.i_deg(:)).';
        P_list = unique(gridTbl.P(:)).';
        T_list = unique(gridTbl.T(:)).';

        % ============================================================
        % Build summary tables
        % ============================================================
        [best_table, feasible_table, frontier_table] = ...
            local_build_summary_tables(gridTbl, feasible_grid, i_list);

        log_msg(log_fid, 'INFO', 'Grid size      : %d', height(gridTbl));
        log_msg(log_fid, 'INFO', 'Feasible count : %d', height(feasible_grid));
        log_msg(log_fid, 'INFO', 'Inclination bins: %d', numel(i_list));
    
        if ~isempty(best_table)
            log_msg(log_fid, 'INFO', ...
                'Best feasible confirmed: i=%.1f deg | P=%d | T=%d | Ns=%d | D_G_min=%.3f | pass_ratio=%.3f', ...
                best_table.i_deg(1), best_table.P(1), best_table.T(1), ...
                best_table.Ns(1), best_table.D_G_min(1), best_table.pass_ratio(1));
        else
            log_msg(log_fid, 'INFO', 'No feasible configuration found in Stage05 cache.');
        end
    
        % ============================================================
        % Export tables
        % ============================================================
        best_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_best_feasible_%s.csv', timestamp));
        feasible_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_feasible_sorted_%s.csv', timestamp));
        frontier_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_inclination_frontier_%s.csv', timestamp));
    
        writetable(best_table, best_table_file);
        writetable(feasible_table, feasible_table_file);
        writetable(frontier_table, frontier_table_file);
    
        log_msg(log_fid, 'INFO', 'Best table saved to    : %s', best_table_file);
        log_msg(log_fid, 'INFO', 'Feasible table saved to: %s', feasible_table_file);
        log_msg(log_fid, 'INFO', 'Frontier table saved to: %s', frontier_table_file);
    
        % ============================================================
        % Make figures
        % ============================================================
        fig_files = struct();
    
        % 1) feasible scatter
        fig1 = local_plot_feasible_scatter(feasible_grid);
        fig_files.scatter = fullfile(cfg.paths.figs, ...
            sprintf('stage05_feasible_scatter_%s.png', timestamp));
        exportgraphics(fig1, fig_files.scatter, 'Resolution', 200);
        close(fig1);
        log_msg(log_fid, 'INFO', 'Figure saved: %s', fig_files.scatter);
    
        % 2) inclination frontier
        fig2 = local_plot_frontier(frontier_table);
        fig_files.frontier = fullfile(cfg.paths.figs, ...
            sprintf('stage05_inclination_frontier_%s.png', timestamp));
        exportgraphics(fig2, fig_files.frontier, 'Resolution', 200);
        close(fig2);
        log_msg(log_fid, 'INFO', 'Figure saved: %s', fig_files.frontier);
    
        % 3) min-Ns feasible heatmap over (i, P)
        fig3 = local_plot_heatmap_minNs(gridTbl, i_list, P_list);
        fig_files.heatmap_minNs = fullfile(cfg.paths.figs, ...
            sprintf('stage05_heatmap_minNs_%s.png', timestamp));
        exportgraphics(fig3, fig_files.heatmap_minNs, 'Resolution', 200);
        close(fig3);
        log_msg(log_fid, 'INFO', 'Figure saved: %s', fig_files.heatmap_minNs);
    
        % 4) best-D_G feasible heatmap over (i, P)
        fig4 = local_plot_heatmap_bestDG(gridTbl, i_list, P_list);
        fig_files.heatmap_bestDG = fullfile(cfg.paths.figs, ...
            sprintf('stage05_heatmap_bestDG_%s.png', timestamp));
        exportgraphics(fig4, fig_files.heatmap_bestDG, 'Resolution', 200);
        close(fig4);
        log_msg(log_fid, 'INFO', 'Figure saved: %s', fig_files.heatmap_bestDG);
    
        % 5) pass-ratio profile over Ns for each i (feasible subset emphasized)
        fig5 = local_plot_passratio_profile(gridTbl, i_list);
        fig_files.passratio_profile = fullfile(cfg.paths.figs, ...
            sprintf('stage05_passratio_profile_%s.png', timestamp));
        exportgraphics(fig5, fig_files.passratio_profile, 'Resolution', 200);
        close(fig5);
        log_msg(log_fid, 'INFO', 'Figure saved: %s', fig_files.passratio_profile);
    
        % ============================================================
        % Save cache
        % ============================================================
        outp = struct();
        outp.cfg = cfg;
        outp.stage05_file = stage05_file;
        outp.log_file = log_file;
        outp.best_table = best_table;
        outp.feasible_table = feasible_table;
        outp.frontier_table = frontier_table;
        outp.fig_files = fig_files;
        outp.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        plot_cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage05_plot_nominal_results_%s.mat', timestamp));
        save(plot_cache_file, 'outp', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Plot cache saved to: %s', plot_cache_file);
        log_msg(log_fid, 'INFO', 'Stage05.3 finished.');
    
        fprintf('\n');
        fprintf('========== Stage05.3 Summary ==========\n');
        fprintf('Stage05 cache  : %s\n', stage05_file);
        fprintf('Log file       : %s\n', log_file);
        fprintf('Best table     : %s\n', best_table_file);
        fprintf('Feasible table : %s\n', feasible_table_file);
        fprintf('Frontier table : %s\n', frontier_table_file);
        fprintf('Fig scatter    : %s\n', fig_files.scatter);
        fprintf('Fig frontier   : %s\n', fig_files.frontier);
        fprintf('Fig minNs      : %s\n', fig_files.heatmap_minNs);
        fprintf('Fig bestDG     : %s\n', fig_files.heatmap_bestDG);
        fprintf('Fig passratio  : %s\n', fig_files.passratio_profile);
        fprintf('Plot cache     : %s\n', plot_cache_file);
        fprintf('=======================================\n');
    end
    
    % =========================================================================
    % local helpers
    % =========================================================================
    
    function gridTbl = local_normalize_grid(gridTbl)
        % unify feasible field name for Stage05.2b-compatible caches
        if ~ismember('feasible_flag', gridTbl.Properties.VariableNames)
            if ismember('feasible', gridTbl.Properties.VariableNames)
                gridTbl.feasible_flag = logical(gridTbl.feasible);
            else
                error('Grid does not contain feasible_flag or feasible.');
            end
        end

        if ~ismember('failed_early', gridTbl.Properties.VariableNames)
            if ismember('early_stop', gridTbl.Properties.VariableNames)
                gridTbl.failed_early = logical(gridTbl.early_stop);
            else
                gridTbl.failed_early = false(height(gridTbl),1);
            end
        end

        if ~ismember('n_case_evaluated', gridTbl.Properties.VariableNames)
            if ismember('nCaseEval', gridTbl.Properties.VariableNames)
                gridTbl.n_case_evaluated = gridTbl.nCaseEval;
            else
                gridTbl.n_case_evaluated = nan(height(gridTbl),1);
            end
        end
    end
    
    function feasible_grid = local_sort_feasible_grid(feasible_grid)
        if isempty(feasible_grid)
            return;
        end
    
        sort_vars = {};
        sort_dirs = {};
    
        if ismember('Ns', feasible_grid.Properties.VariableNames)
            sort_vars{end+1} = 'Ns'; %#ok<AGROW>
            sort_dirs{end+1} = 'ascend'; %#ok<AGROW>
        end
    
        if ismember('rank_score', feasible_grid.Properties.VariableNames)
            sort_vars{end+1} = 'rank_score'; %#ok<AGROW>
            sort_dirs{end+1} = 'ascend'; %#ok<AGROW>
        end
    
        if ismember('D_G_min', feasible_grid.Properties.VariableNames)
            sort_vars{end+1} = 'D_G_min'; %#ok<AGROW>
            sort_dirs{end+1} = 'descend'; %#ok<AGROW>
        end
    
        if ismember('pass_ratio', feasible_grid.Properties.VariableNames)
            sort_vars{end+1} = 'pass_ratio'; %#ok<AGROW>
            sort_dirs{end+1} = 'descend'; %#ok<AGROW>
        end
    
        feasible_grid = sortrows(feasible_grid, sort_vars, sort_dirs);
    end
    
    function [best_table, feasible_table, frontier_table] = local_build_summary_tables(gridTbl, feasible_grid, i_list)
        % overall best
        if isempty(feasible_grid)
            best_table = table();
            feasible_table = table();
            frontier_table = table();
            return;
        end
    
        best = feasible_grid(1,:);
    
        best_table = table( ...
            best.i_deg, best.Ns, best.P, best.T, best.D_G_min, best.pass_ratio, ...
            best.lambda_worst_min, best.lambda_worst_mean, best.n_case_evaluated, ...
            best.failed_early, ...
            'VariableNames', {'i_deg','Ns','P','T','D_G_min','pass_ratio', ...
                              'lambda_worst_min','lambda_worst_mean','n_case_evaluated','failed_early'});
    
        if ismember('rank_score', best.Properties.VariableNames)
            best_table.rank_score = best.rank_score;
        end
    
        feasible_table = feasible_grid;
    
        % inclination-wise frontier
        rows = [];
        for k = 1:numel(i_list)
            ii = i_list(k);
            sub = feasible_grid(feasible_grid.i_deg == ii, :);
            if isempty(sub)
                continue;
            end
    
            sub = local_sort_feasible_grid(sub);
            rr = sub(1,:);
    
            tmp = table( ...
                rr.i_deg, rr.Ns, rr.P, rr.T, rr.D_G_min, rr.pass_ratio, ...
                rr.lambda_worst_min, rr.lambda_worst_mean, rr.n_case_evaluated, ...
                'VariableNames', {'i_deg','Ns','P','T','D_G_min','pass_ratio', ...
                                  'lambda_worst_min','lambda_worst_mean','n_case_evaluated'});
    
            if ismember('rank_score', rr.Properties.VariableNames)
                tmp.rank_score = rr.rank_score;
            end
    
            rows = [rows; tmp]; %#ok<AGROW>
        end
    
        frontier_table = rows;
    end
    
    function fig = local_plot_feasible_scatter(feasible_grid)
        fig = figure('Color','w','Position',[100,100,960,560]);
        hold on; grid(gca,'on'); box on;
    
        if isempty(feasible_grid)
            text(0.5, 0.5, 'No feasible configurations found', ...
                'HorizontalAlignment', 'center');
            axis off;
            return;
        end
    
        x = feasible_grid.Ns;
        y = feasible_grid.D_G_min;
        c = feasible_grid.i_deg;
    
        scatter(x, y, 64, c, 'filled', 'MarkerFaceAlpha', 0.85);
        colormap(parula);
        cb = colorbar;
        ylabel(cb, 'inclination i (deg)');
    
        xlabel('total satellites N_s');
        ylabel('D_G_min');
        title('Feasible configurations in (N_s, D_G_min) space');
    
        % mark best
        best = feasible_grid(1,:);
        plot(best.Ns, best.D_G_min, 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
        text(best.Ns, best.D_G_min, ...
            sprintf('  best: i=%.0f, P=%d, T=%d', best.i_deg, best.P, best.T), ...
            'VerticalAlignment', 'bottom');
    end
    
    function fig = local_plot_frontier(frontier_table)
        fig = figure('Color','w','Position',[100,100,980,520]);
    
        if isempty(frontier_table)
            text(0.5, 0.5, 'No feasible frontier available', ...
                'HorizontalAlignment', 'center');
            axis off;
            return;
        end
    
        yyaxis left;
        plot(frontier_table.i_deg, frontier_table.Ns, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
        ylabel('minimum feasible N_s');
        xlabel('inclination i (deg)');
        grid(gca,'on'); hold on; box on;
    
        yyaxis right;
        plot(frontier_table.i_deg, frontier_table.D_G_min, '-s', 'LineWidth', 1.8, 'MarkerSize', 7);
        ylabel('D_G_min of frontier point');
    
        title('Inclination-wise feasible frontier');
    
        for k = 1:height(frontier_table)
            txt = sprintf(' (P=%d,T=%d)', frontier_table.P(k), frontier_table.T(k));
            yyaxis left;
            text(frontier_table.i_deg(k), frontier_table.Ns(k), txt, ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
        end
    end
    
    function fig = local_plot_heatmap_minNs(gridTbl, i_list, P_list)
        fig = figure('Color','w','Position',[100,100,900,520]);

        Z = nan(numel(P_list), numel(i_list));

        for a = 1:numel(P_list)
            for b = 1:numel(i_list)
                sub = gridTbl(gridTbl.P == P_list(a) & gridTbl.i_deg == i_list(b) & gridTbl.feasible_flag > 0, :);
                if ~isempty(sub)
                    Z(a,b) = min(sub.Ns);
                end
            end
        end
    
        imagesc(i_list, P_list, Z);
        set(gca, 'YDir', 'normal');
        xlabel('inclination i (deg)');
        ylabel('P');
        title('Minimum feasible N_s over (i, P)');
        colorbar;
        grid(gca,'on');
    
        for a = 1:numel(P_list)
            for b = 1:numel(i_list)
                if isfinite(Z(a,b))
                    text(i_list(b), P_list(a), sprintf('%d', round(Z(a,b))), ...
                        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                else
                    text(i_list(b), P_list(a), 'X', ...
                        'HorizontalAlignment', 'center');
                end
            end
        end
    end
    
    function fig = local_plot_heatmap_bestDG(gridTbl, i_list, P_list)
        fig = figure('Color','w','Position',[100,100,900,520]);

        Z = nan(numel(P_list), numel(i_list));

        for a = 1:numel(P_list)
            for b = 1:numel(i_list)
                sub = gridTbl(gridTbl.P == P_list(a) & gridTbl.i_deg == i_list(b) & gridTbl.feasible_flag > 0, :);
                if ~isempty(sub)
                    Z(a,b) = max(sub.D_G_min);
                end
            end
        end
    
        imagesc(i_list, P_list, Z);
        set(gca, 'YDir', 'normal');
        xlabel('inclination i (deg)');
        ylabel('P');
        title('Best feasible D_G_min over (i, P)');
        colorbar;
        grid(gca,'on');
    
        for a = 1:numel(P_list)
            for b = 1:numel(i_list)
                if isfinite(Z(a,b))
                    text(i_list(b), P_list(a), sprintf('%.2f', Z(a,b)), ...
                        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                else
                    text(i_list(b), P_list(a), 'X', ...
                        'HorizontalAlignment', 'center');
                end
            end
        end
    end
    
    function fig = local_plot_passratio_profile(gridTbl, i_list)
        fig = figure('Color','w','Position',[100,100,980,560]);
        hold on; grid(gca,'on'); box on;

        if isempty(gridTbl)
            text(0.5, 0.5, 'Empty grid', 'HorizontalAlignment', 'center');
            axis off;
            return;
        end

        for k = 1:numel(i_list)
            ii = i_list(k);
            sub = gridTbl(gridTbl.i_deg == ii, :);
    
            if isempty(sub)
                continue;
            end
    
            % for the same Ns, keep the maximum pass_ratio over (P,T)
            Ns_u = unique(sub.Ns);
            best_pass = nan(size(Ns_u));
            for j = 1:numel(Ns_u)
                tmp = sub(sub.Ns == Ns_u(j), :);
                best_pass(j) = max(tmp.pass_ratio);
            end
    
            plot(Ns_u, best_pass, '-o', 'LineWidth', 1.2, 'MarkerSize', 5, ...
                'DisplayName', sprintf('i=%.0f deg', ii));
        end
    
        xlabel('total satellites N_s');
        ylabel('max pass ratio under fixed i');
        ylim([0, 1.05]);
        title('Pass-ratio profile versus N_s');
        legend('Location', 'eastoutside');
    end
