function out = stage01_scenario_disk()
    %STAGE01_SCENARIO_DISK Build and validate disk-entry scenario casebank.
    
        % ---------------------------
        % Init
        % ---------------------------
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage01_scenario_disk';
        seed_rng(cfg.random.seed);
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.figs);
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage01_scenario_disk_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage01 started.');
        log_msg(log_fid, 'INFO', 'Protected disk radius R_D = %.1f km', cfg.stage01.R_D_km);
        log_msg(log_fid, 'INFO', 'Entry boundary radius R_in = %.1f km', cfg.stage01.R_in_km);
        log_msg(log_fid, 'INFO', 'Nominal entry points = %d', cfg.stage01.num_nominal_entry_points);
        log_msg(log_fid, 'INFO', 'Heading offsets = %s deg', mat2str(cfg.stage01.heading_offsets_deg));
    
        % ---------------------------
        % Build casebank
        % ---------------------------
        casebank = make_casebank_stage01(cfg);
    
        log_msg(log_fid, 'INFO', 'Casebank built successfully.');
        log_msg(log_fid, 'INFO', 'Nominal cases  : %d', casebank.summary.num_nominal);
        log_msg(log_fid, 'INFO', 'Heading cases  : %d', casebank.summary.num_heading);
        log_msg(log_fid, 'INFO', 'Critical cases : %d', casebank.summary.num_critical);
        log_msg(log_fid, 'INFO', 'Total cases    : %d', casebank.summary.num_total);
    
        % ---------------------------
        % Simple validation
        % ---------------------------
        assert(casebank.summary.num_nominal == cfg.stage01.num_nominal_entry_points, ...
            'Nominal case count mismatch.');
    
        assert(casebank.summary.num_heading == ...
            cfg.stage01.num_nominal_entry_points * numel(cfg.stage01.heading_offsets_deg), ...
            'Heading-family case count mismatch.');
    
        assert(casebank.summary.num_total == ...
            casebank.summary.num_nominal + casebank.summary.num_heading + casebank.summary.num_critical, ...
            'Total case count mismatch.');
    
        log_msg(log_fid, 'INFO', 'Basic case-count validation passed.');
    
        % ---------------------------
        % Plot
        % ---------------------------
        fig_file = '';
        if cfg.stage01.make_plot
            fig = plot_scenario_scheme(cfg, casebank);
            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage01_scenario_scheme_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);
            log_msg(log_fid, 'INFO', 'Scenario plot saved to: %s', fig_file);
        end
    
        % ---------------------------
        % Save cache
        % ---------------------------
        out = struct();
        out.cfg = cfg;
        out.casebank = casebank;
        out.stage = cfg.project_stage;
        out.status = 'PASS';
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        out.log_file = log_file;
        out.fig_file = fig_file;
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage01_scenario_disk_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage01 finished successfully.');
    
        fprintf('\n');
        fprintf('========== Stage01 Summary ==========\n');
        fprintf('Status      : %s\n', out.status);
        fprintf('Nominal     : %d\n', casebank.summary.num_nominal);
        fprintf('Heading     : %d\n', casebank.summary.num_heading);
        fprintf('Critical    : %d\n', casebank.summary.num_critical);
        fprintf('Total cases : %d\n', casebank.summary.num_total);
        fprintf('Log file    : %s\n', out.log_file);
        fprintf('Figure      : %s\n', out.fig_file);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=====================================\n');
    end