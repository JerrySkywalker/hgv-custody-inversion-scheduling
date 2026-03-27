function out = stage06_plot_heading_results(cfg)
    %STAGE06_PLOT_HEADING_RESULTS
    % Stage06.5:
    %   Plot comparison figures between Stage05 nominal results and
    %   Stage06 heading-extended physical results.
    %
    % Output figures:
    %   Fig1: feasible scatter compare (Ns vs D_G_min)
    %   Fig2: frontier compare by inclination
    %   Fig3: delta-Ns heatmap on (i,P)
    %   Fig4: pass-ratio envelope compare by inclination
    %
    % Saved to:
    %   outputs/stage/figs/stage06_*.png
    %   outputs/stage/figs/stage06_*.fig

        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage06_prepare_cfg(cfg);
        cfg.project_stage = 'stage06_plot_heading_results';
        cfg = configure_stage_output_paths(cfg);
        run_tag = char(cfg.stage06.run_tag);

        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);

        fig_dir = cfg.paths.figs;
        ensure_dir(fig_dir);

        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_plot_heading_results_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.5 plotting started.');
    
        % ============================================================
        % Load latest Stage05 cache
        % ============================================================
        d5 = find_stage_cache_files(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat');
        assert(~isempty(d5), 'No Stage05 cache found.');
        [~, idx5] = max([d5.datenum]);
        stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
        S5 = load(stage05_file);
        grid05 = S5.out.grid;
    
        % ============================================================
        % Load latest Stage06 cache (by run_tag)
        % ============================================================
        d6 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage06_heading_walker_search_%s_*.mat', run_tag));
        assert(~isempty(d6), 'No Stage06 cache found for run_tag: %s.', run_tag);
        [~, idx6] = max([d6.datenum]);
        stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);
        S6 = load(stage06_file);
        grid06 = S6.out.grid;

        % ============================================================
        % Load latest Stage06 compare cache (by run_tag)
        % ============================================================
        dc = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage06_compare_with_stage05_%s_*.mat', run_tag));
        assert(~isempty(dc), 'No Stage06 compare cache found for run_tag: %s. Please run stage06_compare_with_stage05 first.', run_tag);
        [~, idxc] = max([dc.datenum]);
        compare_file = fullfile(dc(idxc).folder, dc(idxc).name);
        Sc = load(compare_file);
    
        assert(isfield(Sc, 'out'), 'Invalid Stage06 compare cache.');
        cmp = Sc.out;
    
        frontierTbl = cmp.frontier_compare_by_i;
        IPTbl = cmp.IP_compare_minNs;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage05 cache: %s', stage05_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage06 cache: %s', stage06_file);
        log_msg(log_fid, 'INFO', 'Loaded compare cache: %s', compare_file);
    
        % ============================================================
        % Figure 1: feasible scatter compare
        % ============================================================
        fig1 = figure('Name','Stage06 Fig1 Feasible Scatter Compare', 'Color','w');
        hold on; grid on; box on;
    
        feas05 = grid05(grid05.feasible_flag,:);
        feas06 = grid06(grid06.feasible_flag,:);
    
        if ~isempty(feas05)
            scatter(feas05.Ns, feas05.D_G_min, 36, feas05.i_deg, 'o', 'filled', ...
                'DisplayName', 'Stage05 feasible');
        end
        if ~isempty(feas06)
            scatter(feas06.Ns, feas06.D_G_min, 50, feas06.i_deg, '^', ...
                'DisplayName', 'Stage06 feasible');
        end
    
        xlabel('N_s');
        ylabel('D_G^{min}');
        title('Stage05 vs Stage06 feasible-set scatter');
        cb1 = colorbar;
        cb1.Label.String = 'Inclination i (deg)';
        legend('Location','best');
    
        f1_png = fullfile(fig_dir, sprintf('stage06_fig1_feasible_scatter_%s_%s.png', run_tag, timestamp));
        f1_fig = fullfile(fig_dir, sprintf('stage06_fig1_feasible_scatter_%s_%s.fig', run_tag, timestamp));
        saveas(fig1, f1_png);
        savefig(fig1, f1_fig);
    
        % ============================================================
        % Figure 2: frontier compare by inclination
        % ============================================================
        fig2 = figure('Name','Stage06 Fig2 Frontier Compare', 'Color','w');
        hold on; grid on; box on;
    
        plot(frontierTbl.i_deg, frontierTbl.min_feasible_Ns_stage05, '-o', 'LineWidth', 1.5, ...
            'MarkerSize', 7, 'DisplayName', 'Stage05 nominal');
        plot(frontierTbl.i_deg, frontierTbl.min_feasible_Ns_stage06, '-s', 'LineWidth', 1.5, ...
            'MarkerSize', 7, 'DisplayName', 'Stage06 heading-extended');
    
        xlabel('Inclination i (deg)');
        ylabel('Minimum feasible N_s');
        title('Frontier shift under heading extension');
        legend('Location','best');
    
        % mark shifted points
        idx_shift = find(~frontierTbl.frontier_same);
        for k = 1:numel(idx_shift)
            ii = idx_shift(k);
            x = frontierTbl.i_deg(ii);
            y = frontierTbl.min_feasible_Ns_stage06(ii);
            text(x, y, sprintf('  \\DeltaN_s=%g', frontierTbl.delta_Ns(ii)), ...
                'FontSize', 9, 'VerticalAlignment','bottom');
        end
    
        f2_png = fullfile(fig_dir, sprintf('stage06_fig2_frontier_compare_%s_%s.png', run_tag, timestamp));
        f2_fig = fullfile(fig_dir, sprintf('stage06_fig2_frontier_compare_%s_%s.fig', run_tag, timestamp));
        saveas(fig2, f2_png);
        savefig(fig2, f2_fig);
    
        % ============================================================
        % Figure 3: delta-Ns heatmap on (i,P)
        % ============================================================
        fig3 = figure('Name','Stage06 Fig3 Delta-Ns Heatmap', 'Color','w');
    
        i_vals = unique(IPTbl.i_deg);
        P_vals = unique(IPTbl.P);
    
        M = nan(numel(i_vals), numel(P_vals));
    
        for ii = 1:numel(i_vals)
            for jj = 1:numel(P_vals)
                mask = IPTbl.i_deg == i_vals(ii) & IPTbl.P == P_vals(jj);
                if any(mask)
                    M(ii,jj) = IPTbl.delta_Ns(find(mask,1,'first'));
                end
            end
        end
    
        imagesc(P_vals, i_vals, M);
        set(gca, 'YDir', 'normal');
        xlabel('P');
        ylabel('Inclination i (deg)');
        title('\DeltaN_s = N_{s,Stage06} - N_{s,Stage05}');
        cb3 = colorbar;
        cb3.Label.String = '\DeltaN_s';
        grid on; box on;
    
        % annotate cells
        for ii = 1:numel(i_vals)
            for jj = 1:numel(P_vals)
                if isfinite(M(ii,jj))
                    text(P_vals(jj), i_vals(ii), sprintf('%g', M(ii,jj)), ...
                        'HorizontalAlignment','center', 'FontSize', 9);
                end
            end
        end
    
        f3_png = fullfile(fig_dir, sprintf('stage06_fig3_deltaNs_heatmap_%s_%s.png', run_tag, timestamp));
        f3_fig = fullfile(fig_dir, sprintf('stage06_fig3_deltaNs_heatmap_%s_%s.fig', run_tag, timestamp));
        saveas(fig3, f3_png);
        savefig(fig3, f3_fig);
    
        % ============================================================
        % Figure 4: pass-ratio envelope compare by inclination
        % ============================================================
        fig4 = figure('Name','Stage06 Fig4 Pass-Ratio Envelope Compare', 'Color','w');
    
        i_list = unique(grid05.i_deg);
        nI = numel(i_list);
    
        tiledlayout(nI,1,'Padding','compact','TileSpacing','compact');
    
        for ii = 1:nI
            i_deg = i_list(ii);
    
            nexttile;
            hold on; grid on; box on;
    
            sub05 = grid05(grid05.i_deg == i_deg,:);
            sub06 = grid06(grid06.i_deg == i_deg,:);
    
            env05 = local_build_pass_envelope(sub05);
            env06 = local_build_pass_envelope(sub06);
    
            plot(env05.Ns, env05.pass_ratio_env, '-o', 'LineWidth', 1.2, ...
                'MarkerSize', 4, 'DisplayName', 'Stage05');
            plot(env06.Ns, env06.pass_ratio_env, '-s', 'LineWidth', 1.2, ...
                'MarkerSize', 4, 'DisplayName', 'Stage06');
    
            ylabel(sprintf('i=%g^\\circ', i_deg));
    
            if ii == 1
                title('Pass-ratio envelope compare by inclination');
                legend('Location','best');
            end
    
            if ii == nI
                xlabel('N_s');
            end
        end
    
        f4_png = fullfile(fig_dir, sprintf('stage06_fig4_passratio_envelope_%s_%s.png', run_tag, timestamp));
        f4_fig = fullfile(fig_dir, sprintf('stage06_fig4_passratio_envelope_%s_%s.fig', run_tag, timestamp));
        saveas(fig4, f4_png);
        savefig(fig4, f4_fig);
    
        % ============================================================
        % Save output struct
        % ============================================================
        out = struct();
        out.stage05_file = stage05_file;
        out.stage06_file = stage06_file;
        out.compare_file = compare_file;
        out.log_file = log_file;
        out.figure_dir = fig_dir;
        out.files = struct();
        out.files.fig1_png = f1_png;
        out.files.fig1_fig = f1_fig;
        out.files.fig2_png = f2_png;
        out.files.fig2_fig = f2_fig;
        out.files.fig3_png = f3_png;
        out.files.fig3_fig = f3_fig;
        out.files.fig4_png = f4_png;
        out.files.fig4_fig = f4_fig;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_plot_heading_results_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Fig1 saved to: %s', f1_png);
        log_msg(log_fid, 'INFO', 'Fig2 saved to: %s', f2_png);
        log_msg(log_fid, 'INFO', 'Fig3 saved to: %s', f3_png);
        log_msg(log_fid, 'INFO', 'Fig4 saved to: %s', f4_png);
        log_msg(log_fid, 'INFO', 'Stage06.5 plotting finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.5 Summary ==========\n');
        fprintf('Figure dir : %s\n', fig_dir);
        fprintf('Fig1 png   : %s\n', f1_png);
        fprintf('Fig2 png   : %s\n', f2_png);
        fprintf('Fig3 png   : %s\n', f3_png);
        fprintf('Fig4 png   : %s\n', f4_png);
        fprintf('Cache      : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    % =========================================================================
    % Local helper: pass-ratio envelope at one inclination
    % =========================================================================
    function envTbl = local_build_pass_envelope(subTbl)
        Ns_list = unique(subTbl.Ns);
        pass_env = nan(numel(Ns_list),1);
    
        for k = 1:numel(Ns_list)
            Ns = Ns_list(k);
            mask = subTbl.Ns == Ns;
            vals = subTbl.pass_ratio(mask);
            pass_env(k) = max(vals, [], 'omitnan');
        end
    
        envTbl = table(Ns_list(:), pass_env, 'VariableNames', {'Ns','pass_ratio_env'});
    end
