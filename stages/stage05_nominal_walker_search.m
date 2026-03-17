function out = stage05_nominal_walker_search(cfg, opts)
    %STAGE05_NOMINAL_WALKER_SEARCH
    % Stage05.2b: nominal-family Walker static search over (i, P, T) with fixed h.
    %
    % Main improvements over Stage05.2a:
    %   - uses parfeval + fetchNext for robust live progress
    %   - prints [SUBMIT] immediately when jobs are dispatched
    %   - prints [LIVE-DONE] immediately when each job finishes
    %   - avoids unreliable live callback behavior under ThreadPool
    %   - keeps auto pool startup, hard-case-first, early-stop, and light cache
    
        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2 || isempty(opts)
            opts = struct();
        end
        cfg.project_stage = 'stage05_nominal_walker_search';
        cfg = configure_stage_output_paths(cfg);
        cfg = local_apply_stage05_opts(cfg, opts);
    
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
    
        log_msg(log_fid, 'INFO', 'Stage05.2b started.');
    
        % ------------------------------------------------------------
        % Load latest Stage04 cache: inherit gamma_req
        % ------------------------------------------------------------
        d4 = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
        assert(~isempty(d4), 'No Stage04 cache found. Please run stage04_window_worstcase first.');
    
        [~, idx4] = max([d4.datenum]);
        stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
        S4 = load(stage04_file);
        assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
        assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
            'Stage04 cache missing summary.gamma_meta');
    
        gamma_req = S4.out.summary.gamma_meta.gamma_req;
        cfg.stage04.gamma_req = gamma_req;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
        log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
    
        % ------------------------------------------------------------
        % Load latest Stage02 cache: use nominal trajectory family
        % ------------------------------------------------------------
        d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
    
        trajs_nominal = S2.out.trajbank.nominal;
        eval_context = local_prepare_eval_context(trajs_nominal, cfg);
        log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));
    
        % ------------------------------------------------------------
        % Hard-case-first ordering from Stage04 nominal results
        % ------------------------------------------------------------
        hard_order = (1:numel(trajs_nominal)).';
        if cfg.stage05.hard_case_first
            try
                if isfield(S4.out.summary, 'margin') && isfield(S4.out.summary.margin, 'case_table')
                    tab4 = S4.out.summary.margin.case_table;
                elseif isfield(S4.out.summary, 'spectrum') && isfield(S4.out.summary.spectrum, 'case_table')
                    tab4 = S4.out.summary.spectrum.case_table;
                else
                    tab4 = table();
                end
    
                if ~isempty(tab4)
                    traj_case_ids = strings(numel(trajs_nominal),1);
                    for k = 1:numel(trajs_nominal)
                        traj_case_ids(k) = string(trajs_nominal(k).case.case_id);
                    end
    
                    if ismember('case_ids', tab4.Properties.VariableNames) && ...
                       ismember('D_G', tab4.Properties.VariableNames) && ...
                       ismember('families', tab4.Properties.VariableNames)
    
                        nominal_rows = strcmp(string(tab4.families), "nominal");
                        tab_nom = tab4(nominal_rows, :);
                        [~, ord] = sort(tab_nom.D_G, 'ascend');
    
                        hard_ids = string(tab_nom.case_ids(ord));
                        hard_order_tmp = nan(numel(hard_ids),1);
    
                        for k = 1:numel(hard_ids)
                            idxk = find(traj_case_ids == hard_ids(k), 1);
                            if ~isempty(idxk)
                                hard_order_tmp(k) = idxk;
                            end
                        end
    
                        hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
                        if numel(hard_order_tmp) == numel(trajs_nominal)
                            hard_order = hard_order_tmp;
                        end
                    end
                end
            catch
                % fallback silently
            end
        end
    
        % ------------------------------------------------------------
        % Build search grid
        % ------------------------------------------------------------
        grid = build_stage05_search_grid(cfg);
        grid.gamma_req(:) = gamma_req;
        nGrid = height(grid);
    
        % ------------------------------------------------------------
        % Pool setup
        % ------------------------------------------------------------
        use_parallel = cfg.stage05.use_parallel;
        use_live_progress = cfg.stage05.use_live_progress;
        if isfield(opts, 'disable_live_progress') && opts.disable_live_progress
            use_live_progress = false;
        end

        requested_profile = string(cfg.stage05.parallel_pool_profile);
        if use_parallel && use_live_progress && requested_profile == "threads"
            log_msg(log_fid, 'INFO', ...
                'Live progress is more reliable with process-based workers. Switching profile from threads to local.');
            requested_profile = "local";
        end
        if use_parallel && ~use_live_progress && requested_profile == "local" && ...
                isfield(cfg.stage05, 'prefer_thread_pool_for_batch') && cfg.stage05.prefer_thread_pool_for_batch
            log_msg(log_fid, 'INFO', ...
                'Batch execution detected without live progress. Switching profile from local to threads.');
            requested_profile = "threads";
        end
    
        if use_parallel && cfg.stage05.auto_start_pool
            pool = ensure_parallel_pool(char(requested_profile), cfg.stage05.parallel_num_workers);
            pool_type = class(pool);
            log_msg(log_fid, 'INFO', ...
                'Parallel mode enabled. RequestedProfile=%s, PoolType=%s, Workers=%d', ...
                requested_profile, pool_type, pool.NumWorkers);
        elseif use_parallel
            pool = gcp('nocreate');
            if isempty(pool)
                error(['cfg.stage05.use_parallel=true but no pool exists. ' ...
                       'Either open pool manually or set auto_start_pool=true.']);
            end
            pool_type = class(pool);
            log_msg(log_fid, 'INFO', ...
                'Parallel mode enabled. ExistingPoolType=%s, Workers=%d', ...
                pool_type, pool.NumWorkers);
        else
            pool = [];
            log_msg(log_fid, 'INFO', 'Parallel mode disabled.');
        end
    
        % ------------------------------------------------------------
        % Preallocate result arrays
        % ------------------------------------------------------------
        save_eval_bank_enabled = isfield(cfg.stage05, 'save_eval_bank') && cfg.stage05.save_eval_bank;
        if isfield(opts, 'disable_eval_bank') && opts.disable_eval_bank
            save_eval_bank_enabled = false;
        end
        if save_eval_bank_enabled
            eval_bank = cell(nGrid,1);
        else
            eval_bank = [];
        end
    
        is_evaluated = false(nGrid,1);
        lambda_worst_min = nan(nGrid,1);
        lambda_worst_mean = nan(nGrid,1);
        D_G_min = nan(nGrid,1);
        D_G_mean = nan(nGrid,1);
        pass_ratio = nan(nGrid,1);
        feasible_flag = false(nGrid,1);
        rank_score = nan(nGrid,1);
        n_case_evaluated = nan(nGrid,1);
        failed_early = false(nGrid,1);
    
        started_count = 0;
        completed_count = 0;
        feasible_count_live = 0;
        t_start = tic;
    
        % ------------------------------------------------------------
        % Evaluate
        % ------------------------------------------------------------
        if use_parallel && use_live_progress
            futures(nGrid,1) = parallel.FevalFuture;
    
            % ---- submit stage ----
            for r = 1:nGrid
                row = grid(r,:);
    
                started_count = started_count + 1;
                if use_live_progress && mod(started_count, cfg.stage05.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[SUBMIT   ] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | elapsed=%.1fs'], ...
                        r, nGrid, row.i_deg, row.P, row.T, row.Ns, elapsed_s);
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
    
                futures(r) = parfeval(pool, @evaluate_single_layer_walker_stage05, 1, ...
                    row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
            end
    
            % ---- collect stage ----
            future_to_grid_idx = 1:nGrid;
    
            for k = 1:nGrid
                [completed_idx, res] = fetchNext(futures);
                r = future_to_grid_idx(completed_idx);
                row = grid(r,:);
    
                if ~isempty(eval_bank)
                    eval_bank{r} = res;
                end
    
                is_evaluated(r) = true;
                lambda_worst_min(r) = res.lambda_worst_min;
                lambda_worst_mean(r) = res.lambda_worst_mean;
                D_G_min(r) = res.D_G_min;
                D_G_mean(r) = res.D_G_mean;
                pass_ratio(r) = res.pass_ratio;
                feasible_flag(r) = res.feasible_flag;
                rank_score(r) = res.rank_score;
                n_case_evaluated(r) = res.n_case_evaluated;
                failed_early(r) = res.failed_early;
    
                completed_count = completed_count + 1;
                feasible_count_live = feasible_count_live + double(res.feasible_flag);
    
                if use_live_progress && mod(completed_count, cfg.stage05.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[LIVE-DONE] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | ' ...
                                   'D_G_min=%.3f | pass_ratio=%.3f | feasible=%d | ' ...
                                   'nCase=%2d | early=%d | feasibleSoFar=%d | elapsed=%.1fs'], ...
                        completed_count, nGrid, row.i_deg, row.P, row.T, row.Ns, ...
                        res.D_G_min, res.pass_ratio, res.feasible_flag, ...
                        res.n_case_evaluated, res.failed_early, feasible_count_live, elapsed_s);
    
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
            end
    
        elseif use_parallel
            result_bank = repmat(local_make_empty_eval_result(), nGrid, 1);
            parfor r = 1:nGrid
                row = grid(r,:);
                result_bank(r) = evaluate_single_layer_walker_stage05(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
            end

            for r = 1:nGrid
                row = grid(r,:);
                res = result_bank(r);

                if ~isempty(eval_bank)
                    eval_bank{r} = res;
                end

                is_evaluated(r) = true;
                lambda_worst_min(r) = res.lambda_worst_min;
                lambda_worst_mean(r) = res.lambda_worst_mean;
                D_G_min(r) = res.D_G_min;
                D_G_mean(r) = res.D_G_mean;
                pass_ratio(r) = res.pass_ratio;
                feasible_flag(r) = res.feasible_flag;
                rank_score(r) = res.rank_score;
                n_case_evaluated(r) = res.n_case_evaluated;
                failed_early(r) = res.failed_early;
            end

            completed_count = nGrid;
            feasible_count_live = sum(feasible_flag);

        else
            for r = 1:nGrid
                row = grid(r,:);
    
                started_count = started_count + 1;
                if use_live_progress && mod(started_count, cfg.stage05.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[SUBMIT   ] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | elapsed=%.1fs'], ...
                        r, nGrid, row.i_deg, row.P, row.T, row.Ns, elapsed_s);
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
    
                res = evaluate_single_layer_walker_stage05(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
    
                if ~isempty(eval_bank)
                    eval_bank{r} = res;
                end
    
                is_evaluated(r) = true;
                lambda_worst_min(r) = res.lambda_worst_min;
                lambda_worst_mean(r) = res.lambda_worst_mean;
                D_G_min(r) = res.D_G_min;
                D_G_mean(r) = res.D_G_mean;
                pass_ratio(r) = res.pass_ratio;
                feasible_flag(r) = res.feasible_flag;
                rank_score(r) = res.rank_score;
                n_case_evaluated(r) = res.n_case_evaluated;
                failed_early(r) = res.failed_early;
    
                completed_count = completed_count + 1;
                feasible_count_live = feasible_count_live + double(res.feasible_flag);
    
                if use_live_progress && mod(completed_count, cfg.stage05.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[LIVE-DONE] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | ' ...
                                   'D_G_min=%.3f | pass_ratio=%.3f | feasible=%d | ' ...
                                   'nCase=%2d | early=%d | feasibleSoFar=%d | elapsed=%.1fs'], ...
                        completed_count, nGrid, row.i_deg, row.P, row.T, row.Ns, ...
                        res.D_G_min, res.pass_ratio, res.feasible_flag, ...
                        res.n_case_evaluated, res.failed_early, feasible_count_live, elapsed_s);
    
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
            end
        end
    
        % ------------------------------------------------------------
        % Write back to grid
        % ------------------------------------------------------------
        grid.is_evaluated = is_evaluated;
        grid.lambda_worst_min = lambda_worst_min;
        grid.lambda_worst_mean = lambda_worst_mean;
        grid.D_G_min = D_G_min;
        grid.D_G_mean = D_G_mean;
        grid.pass_ratio = pass_ratio;
        grid.feasible_flag = feasible_flag;
        grid.rank_score = rank_score;
        grid.n_case_evaluated = n_case_evaluated;
        grid.failed_early = failed_early;
    
        % ------------------------------------------------------------
        % Sort feasible candidates
        % ------------------------------------------------------------
        feasible_grid = grid(grid.feasible_flag, :);
        if ~isempty(feasible_grid)
            feasible_grid = sortrows(feasible_grid, {'Ns','rank_score','D_G_mean'}, {'ascend','ascend','descend'});
        end
    
        % ------------------------------------------------------------
        % Summary
        % ------------------------------------------------------------
        summary = summarize_stage05_grid(grid, cfg);
        summary.gamma_req = gamma_req;
        summary.num_feasible = sum(grid.feasible_flag);
        summary.num_failed_early = sum(grid.failed_early);
        summary.walltime_s = toc(t_start);
    
        if ~isempty(feasible_grid)
            summary.best_feasible = feasible_grid(1,:);
            log_msg(log_fid, 'INFO', ...
                'Best feasible: i=%.1f deg | P=%d | T=%d | Ns=%d | D_G_min=%.3f | pass_ratio=%.3f', ...
                feasible_grid.i_deg(1), feasible_grid.P(1), feasible_grid.T(1), feasible_grid.Ns(1), ...
                feasible_grid.D_G_min(1), feasible_grid.pass_ratio(1));
        else
            summary.best_feasible = table();
            log_msg(log_fid, 'INFO', 'No feasible configuration found under current criterion.');
        end
    
        log_msg(log_fid, 'INFO', 'Evaluated grid size: %d', height(grid));
        log_msg(log_fid, 'INFO', 'Feasible count: %d', summary.num_feasible);
        log_msg(log_fid, 'INFO', 'Early-stop count: %d', summary.num_failed_early);
        log_msg(log_fid, 'INFO', 'Wall time: %.2f s', summary.walltime_s);
    
        % ------------------------------------------------------------
        % Export tables
        % ------------------------------------------------------------
        table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_nominal_search_results_%s.csv', timestamp));
        writetable(grid, table_file);
        log_msg(log_fid, 'INFO', 'Search result table saved to: %s', table_file);
    
        feasible_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage05_nominal_search_feasible_%s.csv', timestamp));
        writetable(feasible_grid, feasible_table_file);
        log_msg(log_fid, 'INFO', 'Feasible table saved to: %s', feasible_table_file);
    
        % ------------------------------------------------------------
        % Save cache
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.grid = grid;
        out.feasible_grid = feasible_grid;
        out.summary = summary;
    
        if ~isempty(eval_bank)
            out.eval_bank = eval_bank;
        end
    
        out.stage02_file = stage02_file;
        out.stage04_file = stage04_file;
        out.log_file = log_file;
        out.table_file = table_file;
        out.feasible_table_file = feasible_table_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage05_nominal_walker_search_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage05.2b finished.');
    
        fprintf('\n');
        fprintf('========== Stage05.2b Summary ==========\n');
        fprintf('Log file       : %s\n', out.log_file);
        fprintf('Result table   : %s\n', out.table_file);
        fprintf('Feasible table : %s\n', out.feasible_table_file);
        fprintf('Cache          : %s\n', cache_file);
        fprintf('Grid size      : %d\n', height(out.grid));
        fprintf('Feasible count : %d\n', summary.num_feasible);
        fprintf('Early-stop cnt : %d\n', summary.num_failed_early);
        fprintf('Wall time (s)  : %.2f\n', summary.walltime_s);
        fprintf('========================================\n');
    end

    function cfg = local_apply_stage05_opts(cfg, opts)
        if ~isfield(opts, 'mode') || isempty(opts.mode)
            return;
        end

        use_parallel = strcmpi(string(opts.mode), "parallel");
        cfg.stage05.use_parallel = use_parallel;

        if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
            opts.parallel_config = struct();
        end
        if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
            opts.parallel_config.enabled = use_parallel;
        end
        if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
            opts.parallel_config.profile_name = cfg.stage05.parallel_pool_profile;
        end
        if ~isfield(opts.parallel_config, 'num_workers')
            opts.parallel_config.num_workers = cfg.stage05.parallel_num_workers;
        end
        if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
            opts.parallel_config.auto_start_pool = cfg.stage05.auto_start_pool;
        end

        cfg.stage05.use_parallel = use_parallel && opts.parallel_config.enabled;
        cfg.stage05.parallel_pool_profile = opts.parallel_config.profile_name;
        cfg.stage05.parallel_num_workers = opts.parallel_config.num_workers;
        cfg.stage05.auto_start_pool = opts.parallel_config.auto_start_pool;
    end

    function result = local_make_empty_eval_result()
        result = struct( ...
            'walker', struct(), ...
            'satbank', struct(), ...
            'case_table', table(), ...
            'lambda_worst_min', NaN, ...
            'lambda_worst_mean', NaN, ...
            'D_G_min', NaN, ...
            'D_G_mean', NaN, ...
            'pass_ratio', NaN, ...
            'feasible_flag', false, ...
            'rank_score', NaN, ...
            'n_case_total', NaN, ...
            'n_case_evaluated', NaN, ...
            'failed_early', false);
    end

    function eval_context = local_prepare_eval_context(trajs_nominal, cfg)
        t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_nominal);
        t_max = max(t_end_all);
        dt = cfg.stage02.Ts_s;

        eval_context = struct();
        eval_context.t_s_common = (0:dt:t_max).';
    end
