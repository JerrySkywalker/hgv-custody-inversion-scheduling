function out = stage00_bootstrap()
    %STAGE00_BOOTSTRAP Bootstrap the fresh-start Chapter 4 experiment project.
    %
    % This stage verifies:
    %   1) startup path initialization
    %   2) result folders creation
    %   3) default config loading
    %   4) logging
    %   5) safe MAT saving
    %   6) minimal debug summary output
    
        % ---------------------------
        % Initialize project
        % ---------------------------
        startup();
    
        % ---------------------------
        % Load default config
        % ---------------------------
        cfg = default_params();
        cfg.project_stage = 'stage00_bootstrap';
    
        % ---------------------------
        % Seed RNG
        % ---------------------------
        seed_rng(cfg.random.seed);
    
        % ---------------------------
        % Prepare log file
        % ---------------------------
        ensure_dir(cfg.paths.logs);
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage00_bootstrap_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
    
        cleanupObj = onCleanup(@() fclose(log_fid));
    
        % ---------------------------
        % Log header
        % ---------------------------
        log_msg(log_fid, 'INFO', 'Stage00 started.');
        log_msg(log_fid, 'INFO', 'Project name: %s', cfg.project_name);
        log_msg(log_fid, 'INFO', 'Project stage: %s', cfg.project_stage);
        log_msg(log_fid, 'INFO', 'Root path: %s', cfg.paths.root);
        log_msg(log_fid, 'INFO', 'Random seed: %d', cfg.random.seed);
    
        % ---------------------------
        % Dummy numeric summary for debug
        % ---------------------------
        dummy = randn(100, 1);
        dummy_summary = summarize_array(dummy, 'dummy_randn_100x1');
    
        log_msg(log_fid, 'INFO', 'Dummy summary: size=%s, min=%.4f, max=%.4f, mean=%.4f, std=%.4f', ...
            mat2str(dummy_summary.size), ...
            dummy_summary.min, dummy_summary.max, dummy_summary.mean, dummy_summary.std);
    
        % ---------------------------
        % Build output struct
        % ---------------------------
        out = struct();
        out.cfg = cfg;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        out.log_file = log_file;
        out.dummy_summary = dummy_summary;
        out.status = 'PASS';
    
        % ---------------------------
        % Save MAT cache
        % ---------------------------
        ensure_dir(cfg.paths.cache);
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage00_bootstrap_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
    
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage00 finished successfully.');
    
        % ---------------------------
        % Console summary
        % ---------------------------
        fprintf('\n');
        fprintf('========== Stage00 Summary ==========\n');
        fprintf('Status   : %s\n', out.status);
        fprintf('Log file : %s\n', out.log_file);
        fprintf('Cache    : %s\n', cache_file);
        fprintf('=====================================\n');
    end