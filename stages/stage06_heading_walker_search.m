function out = stage06_heading_walker_search(cfg, opts)
    %STAGE06_HEADING_WALKER_SEARCH
    % Stage06.3: heading-extended-family Walker static search over (i, P, T) with fixed h.
    %
    % Main features:
    %   - inherits gamma_req from Stage04
    %   - loads Stage02 nominal trajbank
    %   - expands family using Stage06 heading offsets
    %   - uses parfeval + fetchNext for live progress
    %   - keeps early-stop and light cache
    %   - exports Stage06-specific result tables

        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2 || isempty(opts)
            opts = struct();
        end
        cfg = stage06_prepare_cfg(cfg);
        cfg.project_stage = 'stage06_heading_walker_search';
        cfg = local_apply_stage06_opts(cfg, opts);
        run_tag = char(cfg.stage06.run_tag);

        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);

        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_heading_walker_search_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.3 started.');
    
        % ------------------------------------------------------------
        % Load latest Stage04 cache: inherit gamma_req
        % ------------------------------------------------------------
        d4 = dir(fullfile(cfg.paths.cache, 'stage04_window_worstcase_*.mat'));
        assert(~isempty(d4), 'No Stage04 cache found. Please run stage04_window_worstcase first.');
    
        [~, idx4] = max([d4.datenum]);
        stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
        S4 = load(stage04_file);
    
        assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
        assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
            'Stage04 cache missing summary.gamma_meta');
    
        gamma_req = S4.out.summary.gamma_meta.gamma_req;
        cfg.stage04.gamma_req = gamma_req;
        cfg.stage06.gamma_req = gamma_req;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
        log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
    
        % ------------------------------------------------------------
        % Load latest Stage02 cache
        % ------------------------------------------------------------
        d2 = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
    
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
    
        trajs_nominal = S2.out.trajbank.nominal;
        log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));
    
        % ------------------------------------------------------------
        % Build heading-extended family
        % ------------------------------------------------------------
        heading_offsets_deg = cfg.stage06.active_heading_offsets_deg(:).';
        trajs_heading = stage06_build_heading_family( ...
            trajs_nominal, heading_offsets_deg, ...
            'HeadingMode', local_heading_mode_label(cfg.stage06, heading_offsets_deg), ...
            'FamilyType', cfg.stage06.family_scope);
    
        family_size = numel(trajs_heading);
    
        log_msg(log_fid, 'INFO', 'Family type = %s', string(cfg.stage06.family_scope));
        log_msg(log_fid, 'INFO', 'Heading offsets (deg) = %s', mat2str(heading_offsets_deg));
        log_msg(log_fid, 'INFO', 'Heading family size = %d', family_size);
    
        % ------------------------------------------------------------
        % Hard-case-first ordering
        % Stage06.1 explicitly disables reuse of Stage05 nominal hard ordering.
        % ------------------------------------------------------------
        hard_order = (1:family_size).';
        if isfield(cfg.stage06, 'hard_case_first') && cfg.stage06.hard_case_first
            hard_order = local_build_heading_hard_order(trajs_heading);
        end
    
        % ------------------------------------------------------------
        % Build search grid
        % ------------------------------------------------------------
        grid = build_stage06_search_grid(cfg);
        grid.gamma_req(:) = gamma_req;
        nGrid = height(grid);
    
        % ------------------------------------------------------------
        % Pool setup
        % ------------------------------------------------------------
        use_parallel = cfg.stage06.use_parallel;
        use_live_progress = cfg.stage06.use_live_progress;
        if isfield(opts, 'disable_live_progress') && opts.disable_live_progress
            use_live_progress = false;
        end

        requested_profile = string(cfg.stage06.parallel_pool_profile);
        if use_parallel && use_live_progress && requested_profile == "threads"
            log_msg(log_fid, 'INFO', ...
                'Live progress is more reliable with process-based workers. Switching profile from threads to local.');
            requested_profile = "local";
        end
    
        if use_parallel && cfg.stage06.auto_start_pool
            pool = ensure_parallel_pool(char(requested_profile), cfg.stage06.parallel_num_workers);
            pool_type = class(pool);
            log_msg(log_fid, 'INFO', ...
                'Parallel mode enabled. RequestedProfile=%s, PoolType=%s, Workers=%d', ...
                requested_profile, pool_type, pool.NumWorkers);
        elseif use_parallel
            pool = gcp('nocreate');
            if isempty(pool)
                error(['cfg.stage06.use_parallel=true but no pool exists. ' ...
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
        save_eval_bank_enabled = isfield(cfg.stage06, 'save_eval_bank') && cfg.stage06.save_eval_bank;
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
    
            for r = 1:nGrid
                row = grid(r,:);
    
                started_count = started_count + 1;
                if use_live_progress && mod(started_count, cfg.stage06.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[SUBMIT   ] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | ' ...
                                   'family=%s | nCase=%2d | elapsed=%.1fs'], ...
                        r, nGrid, row.i_deg, row.P, row.T, row.Ns, ...
                        char(cfg.stage06.family_scope), family_size, elapsed_s);
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
    
                futures(r) = parfeval(pool, @evaluate_single_layer_walker_stage06, 1, ...
                    row, trajs_heading, gamma_req, cfg, hard_order);
            end
    
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
    
                if use_live_progress && mod(completed_count, cfg.stage06.progress_every) == 0
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
                result_bank(r) = evaluate_single_layer_walker_stage06(row, trajs_heading, gamma_req, cfg, hard_order);
            end

            for r = 1:nGrid
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
                if use_live_progress && mod(started_count, cfg.stage06.progress_every) == 0
                    elapsed_s = toc(t_start);
                    msg = sprintf(['[SUBMIT   ] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | ' ...
                                   'family=%s | nCase=%2d | elapsed=%.1fs'], ...
                        r, nGrid, row.i_deg, row.P, row.T, row.Ns, ...
                        char(cfg.stage06.family_scope), family_size, elapsed_s);
                    fprintf('%s\n', msg);
                    log_msg(log_fid, 'INFO', '%s', msg);
                end
    
                res = evaluate_single_layer_walker_stage06(row, trajs_heading, gamma_req, cfg, hard_order);
    
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
    
                if use_live_progress && mod(completed_count, cfg.stage06.progress_every) == 0
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
        summary = summarize_stage06_grid(grid, cfg);
        summary.gamma_req = gamma_req;
        summary.num_feasible = sum(grid.feasible_flag);
        summary.num_failed_early = sum(grid.failed_early);
        summary.walltime_s = toc(t_start);
        summary.family_size = family_size;
        summary.heading_offsets_deg = heading_offsets_deg;
    
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
            sprintf('stage06_heading_search_results_%s_%s.csv', run_tag, timestamp));
        writetable(grid, table_file);
        log_msg(log_fid, 'INFO', 'Search result table saved to: %s', table_file);

        feasible_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_search_feasible_%s_%s.csv', run_tag, timestamp));
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
    
        out.trajs_heading = trajs_heading;
        out.stage02_file = stage02_file;
        out.stage04_file = stage04_file;
        out.log_file = log_file;
        out.table_file = table_file;
        out.feasible_table_file = feasible_table_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_heading_walker_search_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage06.3 finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.3 Summary ==========\n');
        fprintf('Log file       : %s\n', out.log_file);
        fprintf('Result table   : %s\n', out.table_file);
        fprintf('Feasible table : %s\n', out.feasible_table_file);
        fprintf('Cache          : %s\n', cache_file);
        fprintf('Family size    : %d\n', family_size);
        fprintf('Grid size      : %d\n', height(out.grid));
        fprintf('Feasible count : %d\n', summary.num_feasible);
        fprintf('Early-stop cnt : %d\n', summary.num_failed_early);
        fprintf('Wall time (s)  : %.2f\n', summary.walltime_s);
        fprintf('=======================================\n');
    end
    
    % =========================================================================
    % local helpers
    % =========================================================================
    function mode_label = local_heading_mode_label(stage06_cfg, heading_offsets_deg)
        h = sort(heading_offsets_deg(:).');
        if isequal(h, sort(stage06_cfg.heading_offsets_small_deg(:).'))
            mode_label = "small";
        elseif isequal(h, sort(stage06_cfg.heading_offsets_full_deg(:).'))
            mode_label = "full";
        else
            mode_label = "custom";
        end
    end
    
    function hard_order = local_build_heading_hard_order(trajs_heading)
    % Optional Stage06 hard-order rule:
    %   prioritize larger |heading_offset| first, then keep original order.
    
        n = numel(trajs_heading);
        idx = (1:n).';
        abs_offset = zeros(n,1);
    
        for k = 1:n
            if isfield(trajs_heading(k).case, 'heading_offset_deg')
                abs_offset(k) = abs(trajs_heading(k).case.heading_offset_deg);
            end
        end
    
        tmp = table(idx, abs_offset);
        tmp = sortrows(tmp, {'abs_offset','idx'}, {'descend','ascend'});
        hard_order = tmp.idx;
    end

    function cfg = local_apply_stage06_opts(cfg, opts)
        if ~isfield(opts, 'mode') || isempty(opts.mode)
            return;
        end

        use_parallel = strcmpi(string(opts.mode), "parallel");
        cfg.stage06.use_parallel = use_parallel;

        if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
            opts.parallel_config = struct();
        end
        if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
            opts.parallel_config.enabled = use_parallel;
        end
        if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
            opts.parallel_config.profile_name = cfg.stage06.parallel_pool_profile;
        end
        if ~isfield(opts.parallel_config, 'num_workers')
            opts.parallel_config.num_workers = cfg.stage06.parallel_num_workers;
        end
        if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
            opts.parallel_config.auto_start_pool = cfg.stage06.auto_start_pool;
        end

        cfg.stage06.use_parallel = use_parallel && opts.parallel_config.enabled;
        cfg.stage06.parallel_pool_profile = opts.parallel_config.profile_name;
        cfg.stage06.parallel_num_workers = opts.parallel_config.num_workers;
        cfg.stage06.auto_start_pool = opts.parallel_config.auto_start_pool;
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
