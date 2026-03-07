function out = stage04_window_worstcase()
    %STAGE04_WINDOW_WORSTCASE
    % Build windowed information matrices and scan worst windows.
    
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
        satbank = tmp.out.satbank;
        visbank = tmp.out.visbank;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage03 cache: %s', stage03_file);
    
        % ------------------------------------------------------------
        % Run all families
        % ------------------------------------------------------------
        winbank = struct();
        winbank.nominal = local_run_family(visbank.nominal, satbank, log_fid, cfg);
        winbank.heading = local_run_family(visbank.heading, satbank, log_fid, cfg);
        winbank.critical = local_run_family(visbank.critical, satbank, log_fid, cfg);

        summary_extra = summarize_window_bank_stage04(winbank);

        log_msg(log_fid, 'INFO', 'Family summary rows: %d', height(summary_extra.family_summary));
        log_msg(log_fid, 'INFO', 'Heading summary rows: %d', height(summary_extra.heading_summary));
        log_msg(log_fid, 'INFO', 'Critical summary rows: %d', height(summary_extra.critical_summary));

        % ------------------------------------------------------------
        % Example plot
        % ------------------------------------------------------------
        fig_file = '';
        if cfg.stage04.make_plot
            example_win = local_find_case(winbank, cfg.stage04.example_case_id);
            fig = plot_window_case_stage04(example_win.window_case, cfg);

            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage04_window_case_%s_%s.png', cfg.stage04.example_case_id, datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);

            log_msg(log_fid, 'INFO', 'Example window plot saved to: %s', fig_file);
        end

        % ------------------------------------------------------------
        % Family summary plot
        % ------------------------------------------------------------
        fig_family_file = '';
        if cfg.stage04.make_plot
            figfam = plot_window_family_stage04(summary_extra, cfg);
            fig_family_file = fullfile(cfg.paths.figs, ...
                sprintf('stage04_window_family_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(figfam, fig_family_file, 'Resolution', 180);
            close(figfam);

            log_msg(log_fid, 'INFO', 'Family summary plot saved to: %s', fig_family_file);
        end

        % ------------------------------------------------------------
        % Save
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.winbank = winbank;
        out.satbank = satbank;
        out.summary = summary_extra;
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.fig_family_file = fig_family_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage04_window_worstcase_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage04 finished.');
    
        fprintf('\n');
        fprintf('========== Stage04 Summary ==========\n');
        fprintf('Log file  : %s\n', out.log_file);
        fprintf('Figure    : %s\n', out.fig_file);
        fprintf('Cache     : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    function family_out = local_run_family(vis_in, satbank, log_fid, cfg)
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
    
    function hit = local_find_case(winbank, case_id)
        all_structs = [winbank.nominal; winbank.heading; winbank.critical];
        idx = find(strcmp(string({all_structs.case_id}), string(case_id)), 1, 'first');
        assert(~isempty(idx), 'Case %s not found in winbank.', case_id);
        hit = all_structs(idx);
    end