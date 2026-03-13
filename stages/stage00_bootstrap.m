function out = stage00_bootstrap(cfg, opts)
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
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2
            opts = struct();
        end
        opts = local_normalize_opts(cfg, opts);
    
        % ---------------------------
        % Load default config
        % ---------------------------
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
        [dummy_summary, exec_meta] = local_compute_dummy_summary(dummy, opts);

        log_msg(log_fid, 'INFO', 'Dummy summary: size=%s, min=%.4f, max=%.4f, mean=%.4f, std=%.4f', ...
            mat2str(dummy_summary.size), ...
            dummy_summary.min, dummy_summary.max, dummy_summary.mean, dummy_summary.std);
        log_msg(log_fid, 'INFO', 'Execution mode: %s', opts.mode);
        if ~isempty(exec_meta.pool_desc)
            log_msg(log_fid, 'INFO', 'Execution pool: %s', exec_meta.pool_desc);
        end

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
        out.benchmark = struct( ...
            'mode', opts.mode, ...
            'parallel_config', opts.parallel_config, ...
            'execution', exec_meta);
    
        % ---------------------------
        % Save MAT cache
        % ---------------------------
        ensure_dir(cfg.paths.cache);
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage00_bootstrap_%s_%s.mat', opts.mode, datestr(now, 'yyyymmdd_HHMMSS')));

        out.cache_file = cache_file;
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
        fprintf('Mode     : %s\n', opts.mode);
        fprintf('=====================================\n');
    end

function opts = local_normalize_opts(~, opts)
    if ~isfield(opts, 'mode') || isempty(opts.mode)
        opts.mode = 'serial';
    end
    opts.mode = char(lower(string(opts.mode)));

    if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
        opts.parallel_config = struct();
    end

    if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
        opts.parallel_config.enabled = strcmp(opts.mode, 'parallel');
    end
    if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
        opts.parallel_config.profile_name = 'local';
    end
    if ~isfield(opts.parallel_config, 'num_workers')
        opts.parallel_config.num_workers = [];
    end
    if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
        opts.parallel_config.auto_start_pool = true;
    end

end

function [dummy_summary, exec_meta] = local_compute_dummy_summary(dummy, opts)
    exec_meta = struct('used_parallel', false, 'pool_desc', '', 'chunk_count', 1);

    if ~strcmp(opts.mode, 'parallel') || ~opts.parallel_config.enabled
        dummy_summary = summarize_array(dummy, 'dummy_randn_100x1');
        return;
    end

    pool = gcp('nocreate');
    if isempty(pool) && opts.parallel_config.auto_start_pool
        pool = ensure_parallel_pool(opts.parallel_config.profile_name, opts.parallel_config.num_workers);
    end

    if isempty(pool)
        dummy_summary = summarize_array(dummy, 'dummy_randn_100x1');
        return;
    end

    n = numel(dummy);
    nWorkers = max(1, pool.NumWorkers);
    chunk_count = min(nWorkers, n);
    edges = round(linspace(0, n, chunk_count + 1));
    partial_norm = zeros(chunk_count, 1);

    parfor iChunk = 1:chunk_count
        idx1 = edges(iChunk) + 1;
        idx2 = edges(iChunk + 1);
        x = dummy(idx1:idx2);
        partial_norm(iChunk) = norm(x);
    end

    dummy_summary = summarize_array(dummy, 'dummy_randn_100x1');

    exec_meta.used_parallel = true;
    exec_meta.pool_desc = get_parallel_pool_desc(pool, string(opts.parallel_config.profile_name));
    exec_meta.chunk_count = chunk_count;
    exec_meta.partial_norm_sum = sum(partial_norm);
end
