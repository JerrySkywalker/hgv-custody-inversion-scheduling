function out = stage04_window_worstcase()
    %STAGE04_WINDOW_WORSTCASE
    % Build windowed information matrices, scan worst windows,
    % and summarize both spectrum-level and margin-level statistics.
    %
    % Stage04G.6:
    %   - explicitly consumes geodetic/ECI Stage03 results
    %   - preserves current project structure
    %   - adds unified out.summary for easier downstream use
    
        % ------------------------------------------------------------
        % Init
        % ------------------------------------------------------------
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage04_window_worstcase';
        seed_rng(cfg.random.seed);
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.figs);
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage04_window_worstcase_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage04 started.');
    
        % ------------------------------------------------------------
        % Load latest Stage03 cache
        % ------------------------------------------------------------
        d = dir(fullfile(cfg.paths.cache, 'stage03_visibility_pipeline_*.mat'));
        assert(~isempty(d), 'No Stage03 cache found. Please run stage03_visibility_pipeline first.');
    
        [~, idx_latest] = max([d.datenum]);
        stage03_file = fullfile(d(idx_latest).folder, d(idx_latest).name);
    
        tmp = load(stage03_file);
        assert(isfield(tmp, 'out') && isfield(tmp.out, 'satbank') && isfield(tmp.out, 'visbank'), ...
            'Invalid Stage03 cache format: missing out.satbank or out.visbank');
    
        satbank = tmp.out.satbank;
        visbank = tmp.out.visbank;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage03 cache: %s', stage03_file);
    
        if isfield(tmp.out, 'cfg') && isfield(tmp.out.cfg, 'meta') && isfield(tmp.out.cfg.meta, 'scene_mode')
            log_msg(log_fid, 'INFO', 'Inherited scene mode = %s', tmp.out.cfg.meta.scene_mode);
        end
    
        if isfield(satbank, 'meta') && isfield(satbank.meta, 'geometry_mode')
            log_msg(log_fid, 'INFO', 'Satellite geometry mode = %s', satbank.meta.geometry_mode);
        end
    
        % ------------------------------------------------------------
        % Run all families
        % ------------------------------------------------------------
        winbank = struct();
        winbank.nominal = local_run_family(visbank.nominal, satbank, log_fid, cfg);
        winbank.heading = local_run_family(visbank.heading, satbank, log_fid, cfg);
        winbank.critical = local_run_family(visbank.critical, satbank, log_fid, cfg);
    
        % ------------------------------------------------------------
        % Spectrum summaries
        % ------------------------------------------------------------
        summary_spectrum = summarize_window_bank_stage04(winbank);
    
        log_msg(log_fid, 'INFO', 'Family summary rows: %d', height(summary_spectrum.family_summary));
        log_msg(log_fid, 'INFO', 'Heading summary rows: %d', height(summary_spectrum.heading_summary));
        log_msg(log_fid, 'INFO', 'Critical summary rows: %d', height(summary_spectrum.critical_summary));
    
        % ------------------------------------------------------------
        % Margin summaries
        % ------------------------------------------------------------
        summary_margin = summarize_window_margin_bank_stage04(winbank, cfg);
    
        log_msg(log_fid, 'INFO', 'Margin family summary rows: %d', height(summary_margin.family_summary));
        log_msg(log_fid, 'INFO', 'Margin heading summary rows: %d', height(summary_margin.heading_summary));
        log_msg(log_fid, 'INFO', 'Margin critical summary rows: %d', height(summary_margin.critical_summary));
    
        % ------------------------------------------------------------
        % Example plot
        % ------------------------------------------------------------
        fig_file = '';
        if isfield(cfg.stage04, 'make_plot') && cfg.stage04.make_plot
            example_win = local_find_case(winbank, cfg.stage04.example_case_id);
            fig = plot_window_case_stage04(example_win.window_case, cfg);
    
            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage04_window_case_%s_%s.png', ...
                cfg.stage04.example_case_id, datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);
    
            log_msg(log_fid, 'INFO', 'Example window plot saved to: %s', fig_file);
        end
    
        % ------------------------------------------------------------
        % Family spectrum plot
        % ------------------------------------------------------------
        fig_family_file = '';
        if isfield(cfg.stage04, 'make_plot') && cfg.stage04.make_plot
            figfam = plot_window_family_stage04(summary_spectrum, cfg);
            fig_family_file = fullfile(cfg.paths.figs, ...
                sprintf('stage04_window_family_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(figfam, fig_family_file, 'Resolution', 180);
            close(figfam);
    
            log_msg(log_fid, 'INFO', 'Family summary plot saved to: %s', fig_family_file);
        end
    
        % ------------------------------------------------------------
        % Margin plot
        % ------------------------------------------------------------
        fig_margin_file = '';
        if isfield(cfg.stage04, 'make_plot') && cfg.stage04.make_plot
            figm = plot_window_margin_stage04(summary_margin, cfg);
            fig_margin_file = fullfile(cfg.paths.figs, ...
                sprintf('stage04_window_margin_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(figm, fig_margin_file, 'Resolution', 180);
            close(figm);
    
            log_msg(log_fid, 'INFO', 'Margin summary plot saved to: %s', fig_margin_file);
        end
    
        % ------------------------------------------------------------
        % Save
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.winbank = winbank;
        out.satbank = satbank;
    
        out.summary_spectrum = summary_spectrum;
        out.summary_margin = summary_margin;
    
        % unified summary entry for downstream convenience
        out.summary = struct();
        out.summary.spectrum = summary_spectrum;
        out.summary.margin = summary_margin;
    
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.fig_family_file = fig_family_file;
        out.fig_margin_file = fig_margin_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage04_window_worstcase_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage04 finished.');
    
        % ------------------------------------------------------------
        % Console summary
        % ------------------------------------------------------------
        fprintf('\n');
        fprintf('========== Stage04 Summary ==========\n');
        fprintf('Log file        : %s\n', out.log_file);
        fprintf('Figure case     : %s\n', out.fig_file);
        fprintf('Figure family   : %s\n', out.fig_family_file);
        fprintf('Figure margin   : %s\n', out.fig_margin_file);
        fprintf('Cache           : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    % ========================================================================
    % Local helper: run one family
    % ========================================================================
    function family_out = local_run_family(vis_in, satbank, log_fid, cfg)
    
        if isempty(vis_in)
            family_out = struct('case_id', {}, 'window_case', {}, 'summary', {});
            return;
        end
    
        family_out = repmat(struct('case_id', [], 'window_case', [], 'summary', []), numel(vis_in), 1);
    
        for k = 1:numel(vis_in)
            vis_case = vis_in(k).vis_case;
            window_case = scan_worst_window_stage04(vis_case, satbank, cfg);
            s = summarize_window_case_stage04(window_case);
    
            family_out(k).case_id = vis_case.case_id;
            family_out(k).window_case = window_case;
            family_out(k).summary = s;
    
            log_msg(log_fid, 'INFO', ...
                'Case %-24s | lambda_worst=%.3e | lambda_mean=%.3e | t0_worst=%.1f s', ...
                s.case_id, s.lambda_min_worst, s.lambda_min_mean, s.t0_worst_s);
        end
    end
    
    % ========================================================================
    % Local helper: find one case in winbank
    % ========================================================================
    function hit = local_find_case(winbank, case_id)
    
        all_structs = [winbank.nominal; winbank.heading; winbank.critical];
        idx = find(strcmp(string({all_structs.case_id}), string(case_id)), 1, 'first');
        assert(~isempty(idx), 'Case %s not found in winbank.', case_id);
    
        hit = all_structs(idx);
    end