function out = stage05_nominal_walker_search()
    %STAGE05_NOMINAL_WALKER_SEARCH
    % Stage05.2: nominal-family Walker static search over (i, P, T) with fixed h.
    %
    % Supports:
    %   - automatic parallel pool startup
    %   - live progress reporting in parallel mode
    %   - hard-case-first evaluation
    %   - early stop for strict pass-ratio criterion
    
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
    
        log_msg(log_fid, 'INFO', 'Stage05.2 started.');
    
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
    
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
        log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
    
        % ------------------------------------------------------------
        % Load latest Stage02 cache: use nominal trajectory family
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
        % Parallel pool
        % ------------------------------------------------------------
        if cfg.stage05.use_parallel && cfg.stage05.auto_start_pool
            pool = ensure_parallel_pool( ...
                cfg.stage05.parallel_pool_profile, ...
                cfg.stage05.parallel_num_workers);
        
            pool_type = class(pool);
            log_msg(log_fid, 'INFO', ...
                'Parallel mode enabled. RequestedProfile=%s, PoolType=%s, Workers=%d', ...
                string(cfg.stage05.parallel_pool_profile), pool_type, pool.NumWorkers);
        
        elseif cfg.stage05.use_parallel
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
            log_msg(log_fid, 'INFO', 'Parallel mode disabled.');
        end
    
        % ------------------------------------------------------------
        % Preallocate result arrays
        % ------------------------------------------------------------
        eval_bank = cell(nGrid,1);
    
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
    
        % ------------------------------------------------------------
        % Live progress support
        % ------------------------------------------------------------
        completed_count = 0;
        feasible_count_live = 0;
    
        if cfg.stage05.use_parallel && cfg.stage05.use_live_progress
            dq = parallel.pool.DataQueue;
            afterEach(dq, @local_progress_callback);
        else
            dq = [];
        end
    
        % ------------------------------------------------------------
        % Evaluate each design point
        % ------------------------------------------------------------
        if cfg.stage05.use_parallel
            parfor r = 1:nGrid
                row = grid(r,:);
                res = evaluate_single_layer_walker_stage05(row, trajs_nominal, gamma_req, cfg, hard_order);
                eval_bank{r} = res;
    
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
    
                if ~isempty(dq)
                    payload = struct( ...
                        'r', r, ...
                        'nGrid', nGrid, ...
                        'row', row, ...
                        'lambda_worst_min', res.lambda_worst_min, ...
                        'D_G_min', res.D_G_min, ...
                        'pass_ratio', res.pass_ratio, ...
                        'feasible_flag', res.feasible_flag, ...
                        'n_case_evaluated', res.n_case_evaluated, ...
                        'failed_early', res.failed_early);
                    send(dq, payload);
                end
            end
        else
            for r = 1:nGrid
                row = grid(r,:);
                res = evaluate_single_layer_walker_stage05(row, trajs_nominal, gamma_req, cfg, hard_order);
                eval_bank{r} = res;
    
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
    
                log_msg(log_fid, 'INFO', ...
                    ['Grid %3d/%3d | h=%.0f km | i=%5.1f deg | P=%2d | T=%2d | Ns=%3d | ' ...
                     'lambda_min=%.3e | D_G_min=%.3f | pass_ratio=%.3f | feasible=%d | ' ...
                     'nCaseEval=%2d | early=%d'], ...
                    r, nGrid, row.h_km, row.i_deg, row.P, row.T, row.Ns, ...
                    res.lambda_worst_min, res.D_G_min, res.pass_ratio, res.feasible_flag, ...
                    res.n_case_evaluated, res.failed_early);
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
        % If parallel + live progress, still write full results to log once
        % ------------------------------------------------------------
        if cfg.stage05.use_parallel
            for r = 1:nGrid
                row = grid(r,:);
                log_msg(log_fid, 'INFO', ...
                    ['Grid %3d/%3d | h=%.0f km | i=%5.1f deg | P=%2d | T=%2d | Ns=%3d | ' ...
                     'lambda_min=%.3e | D_G_min=%.3f | pass_ratio=%.3f | feasible=%d | ' ...
                     'nCaseEval=%2d | early=%d'], ...
                    r, nGrid, row.h_km, row.i_deg, row.P, row.T, row.Ns, ...
                    grid.lambda_worst_min(r), grid.D_G_min(r), grid.pass_ratio(r), grid.feasible_flag(r), ...
                    grid.n_case_evaluated(r), grid.failed_early(r));
            end
        end
    
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
        out.eval_bank = eval_bank;
        out.summary = summary;
    
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
        log_msg(log_fid, 'INFO', 'Stage05.2 finished.');
    
        fprintf('\n');
        fprintf('========== Stage05.2 Summary ==========\n');
        fprintf('Log file       : %s\n', out.log_file);
        fprintf('Result table   : %s\n', out.table_file);
        fprintf('Feasible table : %s\n', out.feasible_table_file);
        fprintf('Cache          : %s\n', cache_file);
        fprintf('Grid size      : %d\n', height(out.grid));
        fprintf('Feasible count : %d\n', summary.num_feasible);
        fprintf('Early-stop cnt : %d\n', summary.num_failed_early);
        fprintf('=======================================\n');
    
        % nested callback
        function local_progress_callback(payload)
            completed_count = completed_count + 1;
            feasible_count_live = feasible_count_live + double(payload.feasible_flag);
    
            if mod(completed_count, cfg.stage05.progress_every) == 0
                row = payload.row;
                fprintf(['[LIVE] %3d/%3d | i=%5.1f | P=%2d | T=%2d | Ns=%3d | ' ...
                         'D_G_min=%.3f | pass_ratio=%.3f | feasible=%d | nCase=%2d | early=%d\n'], ...
                    completed_count, payload.nGrid, row.i_deg, row.P, row.T, row.Ns, ...
                    payload.D_G_min, payload.pass_ratio, payload.feasible_flag, ...
                    payload.n_case_evaluated, payload.failed_early);
            end
        end
    end