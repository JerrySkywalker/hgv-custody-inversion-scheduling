function out = stage05_nominal_walker_search()
    %STAGE05_NOMINAL_WALKER_SEARCH
    % Stage05.1: search-domain definition and configuration freeze
    %
    % Purpose:
    %   - define Walker search grid over (i, P, T) with fixed h
    %   - lock nominal-family-only evaluation scope
    %   - save grid / config / summary for Stage05.2
    %
    % This stage does NOT run full constellation search yet.
    % It only prepares the search problem.
    
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage05_nominal_walker_search';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage05_nominal_walker_search_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage05.1 started.');
    
        % ------------------------------------------------------------
        % Load latest Stage04 cache only for compatibility / provenance
        % ------------------------------------------------------------
        d4 = dir(fullfile(cfg.paths.cache, 'stage04_window_worstcase_*.mat'));
        assert(~isempty(d4), 'No Stage04 cache found. Please run stage04_window_worstcase first.');
    
        [~, idx4] = max([d4.datenum]);
        stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
        S4 = load(stage04_file);
        assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
    
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
    
        % ------------------------------------------------------------
        % Build search grid
        % ------------------------------------------------------------
        grid = build_stage05_search_grid(cfg);
    
        % ------------------------------------------------------------
        % Freeze search config summary
        % ------------------------------------------------------------
        summary = summarize_stage05_grid(grid, cfg);
    
        log_msg(log_fid, 'INFO', 'Family scope    : %s', cfg.stage05.family_scope);
        log_msg(log_fid, 'INFO', 'Fixed altitude  : %.1f km', cfg.stage05.h_fixed_km);
        log_msg(log_fid, 'INFO', 'Inclination set : %s', mat2str(cfg.stage05.i_grid_deg));
        log_msg(log_fid, 'INFO', 'P set           : %s', mat2str(cfg.stage05.P_grid));
        log_msg(log_fid, 'INFO', 'T set           : %s', mat2str(cfg.stage05.T_grid));
        log_msg(log_fid, 'INFO', 'Grid size       : %d', height(grid));
    
        % ------------------------------------------------------------
        % Export grid table
        % ------------------------------------------------------------
        table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_nominal_search_grid_%s.csv', timestamp));
        writetable(grid, table_file);
        log_msg(log_fid, 'INFO', 'Grid table saved to: %s', table_file);
    
        % ------------------------------------------------------------
        % Save cache
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.grid = grid;
        out.summary = summary;
        out.stage04_file = stage04_file;
        out.log_file = log_file;
        out.table_file = table_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage05_nominal_walker_search_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage05.1 finished.');
    
        fprintf('\n');
        fprintf('========== Stage05.1 Summary ==========\n');
        fprintf('Log file   : %s\n', out.log_file);
        fprintf('Table file : %s\n', out.table_file);
        fprintf('Cache      : %s\n', cache_file);
        fprintf('Grid size  : %d\n', height(out.grid));
        fprintf('=======================================\n');
    end