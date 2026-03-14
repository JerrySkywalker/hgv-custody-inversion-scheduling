function out = stage08_scan_smallgrid_search(cfg, opts)
    %STAGE08_SCAN_SMALLGRID_SEARCH
    % Stage08.4:
    %   Run reduced-grid inversion sensitivity analysis over Tw grid.
    %
    % Parallel strategy:
    %   Parallelize over (config, Tw) task pairs.
    %   Each worker evaluates the full casebank sequentially for one task.
    %
    % Progress feedback:
    %   Real-time progress is reported via parallel.pool.DataQueue.
    %
    % Outputs:
    %   out.scope
    %   out.smallgrid_table
    %   out.raw_config_table
    %   out.Tw_summary_table
    %   out.best_config_table
    %   out.figures
    %   out.files
    
        startup();
    
    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    cfg = stage08_prepare_cfg(cfg);
    cfg = local_prepare_stage08_smallgrid_cfg(cfg);
    cfg = local_apply_stage08_opts(cfg, opts);
    cfg.project_stage = 'stage08_scan_smallgrid_search';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_scan_smallgrid_search_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.4 started.');
    
        [scope_base, nominal_bank, stage08_scope_file, stage02_file] = ...
            local_load_smallgrid_inputs(cfg, run_tag);
        [scope, cfg] = local_apply_smallgrid_scope_overrides(scope_base, cfg, opts);
    
        log_msg(log_fid, 'INFO', 'Loaded Stage02 nominal cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size = %d', numel(nominal_bank));
    
        % ============================================================
        % Resolve casebank / Tw / smallgrid
        % ============================================================
        [casebank_table, case_items, smallgrid_table, Tw_grid_s, sample_type, config_bank, task_table] = ...
            local_prepare_smallgrid_workset(scope, nominal_bank, cfg, stage08_scope_file, stage02_file);
        assert(~isempty(casebank_table), 'Stage08.1 casebank is empty.');

        nCase = height(casebank_table);
        nCfg = height(smallgrid_table);
        nTw = numel(Tw_grid_s);
    
        log_msg(log_fid, 'INFO', ...
            'Casebank cases = %d | small-grid configs = %d | Tw count = %d', ...
            nCase, nCfg, nTw);
    
        log_msg(log_fid, 'INFO', 'Prebuilt casebank case items: %d', nCase);

        nTask = height(task_table);
        log_msg(log_fid, 'INFO', 'Prepared task count = %d', nTask);
    
        % ============================================================
        % Parallel pool
        % ============================================================
        pool_info = local_ensure_parallel_pool(cfg, log_fid);
        use_parallel = pool_info.use_parallel;
    
        % ============================================================
        % Progress monitor
        % ============================================================
        tStart = tic;
        nComplete = 0;
        progress_step = cfg.stage08.smallgrid.progress_step;
    
    disable_progress = cfg.stage08.smallgrid.disable_progress;
    if use_parallel && ~disable_progress
        q = parallel.pool.DataQueue;
        afterEach(q, @progressCallback);
    else
            q = [];
        end
    
        % ============================================================
        % Main loop: parallel over (config, Tw)
        % ============================================================
        raw_rows = cell(nTask, 1);
    
        if use_parallel
            parfor iTask = 1:nTask
                raw_rows{iTask} = local_run_smallgrid_task( ...
                    task_table(iTask, :), config_bank, case_items, sample_type, cfg, q);
            end
        else
            for iTask = 1:nTask
                raw_rows{iTask} = local_run_smallgrid_task( ...
                    task_table(iTask, :), config_bank, case_items, sample_type, cfg, []);
                if ~disable_progress
                    progressCallback(local_make_progress_msg(raw_rows{iTask}, iTask));
                end
            end
        end
    
        raw_config_table = struct2table(vertcat(raw_rows{:}));
    
        % ============================================================
        % Summaries
        % ============================================================
        Tw_summary_table = local_build_Tw_summary_table(raw_config_table);
        best_config_table = local_build_best_config_table(raw_config_table);
    
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.Nmin_vs_Tw = '';
        figures.feasible_ratio_vs_Tw = '';
        figures.num_feasible_vs_Tw = '';
        figures.best_DG_vs_Tw = '';
    
        if cfg.stage08.smallgrid.make_plot
            fig1 = local_plot_Tw_summary(Tw_summary_table, 'N_min', 'N_{min}');
            figures.Nmin_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_Nmin_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.Nmin_vs_Tw, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_Tw_summary(Tw_summary_table, 'feasible_ratio', 'feasible ratio');
            figures.feasible_ratio_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_feasible_ratio_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.feasible_ratio_vs_Tw, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_Tw_summary(Tw_summary_table, 'num_feasible', 'num feasible');
            figures.num_feasible_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_num_feasible_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.num_feasible_vs_Tw, 'Resolution', 180);
            close(fig3);
    
            fig4 = local_plot_best_config_metric(best_config_table, 'D_G_median', 'best D_G_median');
            figures.best_DG_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_best_DG_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig4, figures.best_DG_vs_Tw, 'Resolution', 180);
            close(fig4);
        end
    
        % ============================================================
        % Save CSV
        % ============================================================
        raw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_raw_%s_%s.csv', run_tag, timestamp));
        Tw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_Tw_summary_%s_%s.csv', run_tag, timestamp));
        best_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_best_config_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(raw_config_table, raw_csv);
        writetable(Tw_summary_table, Tw_csv);
        writetable(best_config_table, best_csv);
    
        summary_table = table( ...
            string(stage08_scope_file), ...
            string(stage02_file), ...
            string(cfg.stage08.smallgrid.feasibility_profile), ...
            nCase, ...
            nCfg, ...
            nTw, ...
            nTask, ...
            height(raw_config_table), ...
            height(Tw_summary_table), ...
            height(best_config_table), ...
            use_parallel, ...
            pool_info.num_workers, ...
            toc(tStart), ...
            'VariableNames', { ...
                'stage08_scope_file', ...
                'stage02_file', ...
                'feasibility_profile', ...
                'n_casebank_case', ...
                'n_smallgrid_config', ...
                'n_Tw', ...
                'n_task', ...
                'n_raw_row', ...
                'n_Tw_summary_row', ...
                'n_best_config_row', ...
                'used_parallel', ...
                'num_workers', ...
                'elapsed_seconds'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save outputs
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.casebank_table = casebank_table;
        out.smallgrid_table = smallgrid_table;
        out.task_table = task_table;
        out.raw_config_table = raw_config_table;
        out.Tw_summary_table = Tw_summary_table;
        out.best_config_table = best_config_table;
        out.figures = figures;
        out.summary_table = summary_table;
        out.pool_info = pool_info;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage08_scope_file = stage08_scope_file;
        out.files.stage02_file = stage02_file;
        out.files.raw_csv = raw_csv;
        out.files.Tw_csv = Tw_csv;
        out.files.best_csv = best_csv;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_scan_smallgrid_search_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Raw CSV saved to: %s', raw_csv);
        log_msg(log_fid, 'INFO', 'Tw summary CSV saved to: %s', Tw_csv);
        log_msg(log_fid, 'INFO', 'Best config CSV saved to: %s', best_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.4 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.4 Summary ==========\n');
        fprintf('Stage08.1 scope      : %s\n', stage08_scope_file);
        fprintf('Stage02 nominal      : %s\n', stage02_file);
        fprintf('Casebank cases       : %d\n', nCase);
        fprintf('Small-grid configs   : %d\n', nCfg);
        fprintf('Tw count             : %d\n', nTw);
        fprintf('Task count           : %d\n', nTask);
        fprintf('Used parallel        : %d\n', use_parallel);
        fprintf('Worker count         : %d\n', pool_info.num_workers);
        fprintf('Elapsed seconds      : %.1f\n', toc(tStart));
        fprintf('Raw row count        : %d\n', height(raw_config_table));
        fprintf('Tw summary rows      : %d\n', height(Tw_summary_table));
        fprintf('Best config rows     : %d\n', height(best_config_table));
        fprintf('Raw CSV              : %s\n', raw_csv);
        fprintf('Tw summary CSV       : %s\n', Tw_csv);
        fprintf('Best config CSV      : %s\n', best_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    
        % ============================================================
        % nested callback for progress
        % ============================================================
        function progressCallback(msg)
            nComplete = nComplete + 1;
            do_print = (mod(nComplete, progress_step) == 0) || (nComplete == 1) || (nComplete == nTask);
    
            if do_print
                elapsed_s = toc(tStart);
                line = sprintf(['Progress %3d/%3d | cfg=%2d | Tw=%6.1f s | feasible=%d | ', ...
                                'pass=%.3f | C2=%.3f | DGmed=%.3f | DGmin=%.3f | elapsed=%.1f s'], ...
                    nComplete, nTask, msg.cfg_id, msg.Tw_s, msg.is_feasible, ...
                    msg.pass_geom_ratio, msg.pass_C2_ratio, msg.D_G_median, msg.D_G_min, elapsed_s);
    
                fprintf('%s\n', line);
                log_msg(log_fid, 'INFO', '%s', line);

                % force GUI/command-window update in case callbacks are queued
                drawnow('limitrate');
            end
        end
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    
    function cfg = local_prepare_stage08_smallgrid_cfg(cfg)
    
        if ~isfield(cfg, 'stage08') || ~isstruct(cfg.stage08)
            cfg.stage08 = struct();
        end
        if ~isfield(cfg.stage08, 'smallgrid') || ~isstruct(cfg.stage08.smallgrid)
            cfg.stage08.smallgrid = struct();
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'make_plot') || isempty(cfg.stage08.smallgrid.make_plot)
            cfg.stage08.smallgrid.make_plot = true;
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'require_DG_min') || isempty(cfg.stage08.smallgrid.require_DG_min)
            cfg.stage08.smallgrid.require_DG_min = 1.0;
        end
        if ~isfield(cfg.stage08.smallgrid, 'require_pass_geom_ratio') || isempty(cfg.stage08.smallgrid.require_pass_geom_ratio)
            cfg.stage08.smallgrid.require_pass_geom_ratio = 0.90;
        end
        if ~isfield(cfg.stage08.smallgrid, 'require_C2_pass_ratio') || isempty(cfg.stage08.smallgrid.require_C2_pass_ratio)
            cfg.stage08.smallgrid.require_C2_pass_ratio = 0.50;
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'use_parallel') || isempty(cfg.stage08.smallgrid.use_parallel)
            cfg.stage08.smallgrid.use_parallel = true;
        end
        if ~isfield(cfg.stage08.smallgrid, 'max_workers') || isempty(cfg.stage08.smallgrid.max_workers)
            cfg.stage08.smallgrid.max_workers = inf;
        end
        if ~isfield(cfg.stage08.smallgrid, 'progress_step') || isempty(cfg.stage08.smallgrid.progress_step)
            cfg.stage08.smallgrid.progress_step = 1;
        end
        if ~isfield(cfg.stage08.smallgrid, 'disable_progress') || isempty(cfg.stage08.smallgrid.disable_progress)
            cfg.stage08.smallgrid.disable_progress = false;
        end
        if ~isfield(cfg.stage08.smallgrid, 'prefer_thread_pool_for_batch') || isempty(cfg.stage08.smallgrid.prefer_thread_pool_for_batch)
            cfg.stage08.smallgrid.prefer_thread_pool_for_batch = true;
        end
    end
    
    
    function pool_info = local_ensure_parallel_pool(cfg, log_fid)
    
        pool_info = struct();
        pool_info.use_parallel = false;
        pool_info.num_workers = 0;
        pool_info.pool_type = "";
    
        if ~cfg.stage08.smallgrid.use_parallel
            log_msg(log_fid, 'INFO', 'Parallel disabled by cfg.stage08.smallgrid.use_parallel = false.');
            return;
        end

        profile_name = local_resolve_parallel_profile(cfg);
    
        try
            p = gcp('nocreate');
            if isempty(p)
                max_workers = cfg.stage08.smallgrid.max_workers;
                if isfinite(max_workers)
                    p = parpool(profile_name, min(feature('numcores'), max_workers));
                else
                    p = parpool(profile_name);
                end
            end
    
            pool_info.use_parallel = true;
            pool_info.num_workers = p.NumWorkers;
            pool_info.pool_type = string(class(p));
            log_msg(log_fid, 'INFO', 'Parallel pool ready. workers = %d', p.NumWorkers);
        catch ME
            pool_info.use_parallel = false;
            pool_info.num_workers = 0;
            log_msg(log_fid, 'INFO', 'Parallel pool unavailable. Fallback to serial. Reason: %s', ME.message);
        end
    end

    function profile_name = local_resolve_parallel_profile(cfg)
        profile_name = 'local';
        prefer_threads = isfield(cfg.stage08.smallgrid, 'prefer_thread_pool_for_batch') && ...
            cfg.stage08.smallgrid.prefer_thread_pool_for_batch;
        if prefer_threads && cfg.stage08.smallgrid.disable_progress
            profile_name = 'threads';
        end
    end

    function [scope, nominal_bank, stage08_scope_file, stage02_file] = local_load_smallgrid_inputs(cfg, run_tag)
        persistent cache

        d81 = dir(fullfile(cfg.paths.cache, ...
            sprintf('stage08_define_window_scope_%s_*.mat', run_tag)));
        assert(~isempty(d81), 'No Stage08.1 scope cache found for run_tag=%s.', run_tag);
        [~, idx81] = max([d81.datenum]);
        stage08_scope_file = fullfile(d81(idx81).folder, d81(idx81).name);

        d2 = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        assert(~isempty(d2), 'No Stage02 nominal cache found.');
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);

        cache_hit = isstruct(cache) && ...
            isfield(cache, 'stage08_scope_file') && strcmp(cache.stage08_scope_file, stage08_scope_file) && ...
            isfield(cache, 'stage02_file') && strcmp(cache.stage02_file, stage02_file);

        if ~cache_hit
            S81 = load(stage08_scope_file);
            assert(isfield(S81, 'out') && isfield(S81.out, 'scope'), ...
                'Invalid Stage08.1 cache: missing out.scope');

            S2 = load(stage02_file);
            assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
                'Invalid Stage02 cache: missing out.trajbank.nominal');

            cache = struct();
            cache.stage08_scope_file = stage08_scope_file;
            cache.stage02_file = stage02_file;
            cache.scope = S81.out.scope;
            cache.nominal_bank = S2.out.trajbank.nominal;
        end

        scope = cache.scope;
        nominal_bank = cache.nominal_bank;
    end

    function [casebank_table, case_items, smallgrid_table, Tw_grid_s, sample_type, config_bank, task_table] = ...
            local_prepare_smallgrid_workset(scope, nominal_bank, cfg, stage08_scope_file, stage02_file)
        persistent cache

        casebank_table = local_build_casebank_master_table(scope);
        assert(isfield(scope, 'smallgrid_table') && istable(scope.smallgrid_table) && ...
            ~isempty(scope.smallgrid_table), 'Stage08.1 smallgrid_table is missing or empty.');
        smallgrid_table = scope.smallgrid_table;
        Tw_grid_s = scope.Tw_grid_s(:).';
        sample_type = string(casebank_table.sample_type);
        cache_profile = string(local_get_struct_value(cfg.stage08.smallgrid, 'feasibility_profile', "medium"));
        cache_gamma_req = NaN;
        if isfield(cfg, 'stage04')
            cache_gamma_req = local_get_struct_value(cfg.stage04, 'gamma_req', NaN);
        end
        if ~isfinite(cache_gamma_req)
            if isfield(cfg, 'stage05')
                cache_gamma_req = local_get_struct_value(cfg.stage05, 'require_D_G_min', NaN);
            end
        end

        workset_key = sprintf('%s|%s|ncase%d|ncfg%d|ntw%d|profile%s|gamma%.6g', ...
            stage08_scope_file, stage02_file, height(casebank_table), height(smallgrid_table), ...
            numel(Tw_grid_s), char(cache_profile), cache_gamma_req);
        cache_hit = isstruct(cache) && isfield(cache, 'key') && strcmp(cache.key, workset_key);

        if ~cache_hit
            case_items = cell(height(casebank_table), 1);
            for iCase = 1:height(casebank_table)
                case_items{iCase} = local_build_casebank_case_item(casebank_table(iCase, :), nominal_bank, cfg);
            end

            config_bank = local_build_smallgrid_config_bank(smallgrid_table, cfg);
            task_table = local_build_smallgrid_task_table(smallgrid_table, Tw_grid_s);

            cache = struct();
            cache.key = workset_key;
            cache.case_items = case_items;
            cache.sample_type = sample_type;
            cache.config_bank = config_bank;
            cache.task_table = task_table;
        else
            case_items = cache.case_items;
            sample_type = cache.sample_type;
            config_bank = cache.config_bank;
            task_table = cache.task_table;
        end
    end
    
    
    function task_table = local_build_smallgrid_task_table(smallgrid_table, Tw_grid_s)
    
        nCfg = height(smallgrid_table);
        nTw = numel(Tw_grid_s);
    
        cfg_id = zeros(nCfg * nTw, 1);
        Tw_s = zeros(nCfg * nTw, 1);
    
        ptr = 0;
        for iCfg = 1:nCfg
            for iTw = 1:nTw
                ptr = ptr + 1;
                cfg_id(ptr) = iCfg;
                Tw_s(ptr) = Tw_grid_s(iTw);
            end
        end
    
        task_table = table(cfg_id, Tw_s, 'VariableNames', {'cfg_id', 'Tw_s'});
    end
    
    
    function row = local_run_smallgrid_task(task_row, config_bank, case_items, sample_type, cfg, q)
    
        iCfg = task_row.cfg_id;
        Tw_s = task_row.Tw_s;
    
        cfg_item = config_bank(iCfg);
        walker_cfg = cfg_item.walker_cfg;
        ref_walker = cfg_item.ref_walker;
        gamma_req = cfg_item.gamma_req;
        cfg_label = cfg_item.cfg_label;
    
        cfg_eval = cfg;
        cfg_eval.stage04.Tw_s = Tw_s;
    
        metric = local_evaluate_smallgrid_config_over_casebank( ...
            case_items, sample_type, ref_walker, gamma_req, cfg_eval);
    
        row = local_build_smallgrid_raw_row( ...
            walker_cfg, ref_walker, iCfg, cfg_label, Tw_s, metric);
    
        if ~isempty(q)
            send(q, local_make_progress_msg(row, iCfg));
        end
    end
    
    
    function msg = local_make_progress_msg(row, iCfg)
    
        msg = struct();
        msg.cfg_id = iCfg;
        msg.Tw_s = row.Tw_s;
        msg.is_feasible = row.is_feasible;
        msg.pass_geom_ratio = row.pass_geom_ratio;
        msg.pass_C2_ratio = row.pass_C2_ratio;
        msg.D_G_median = row.D_G_median;
        msg.D_G_min = row.D_G_min;
    end
    
    
    function casebank_table = local_build_casebank_master_table(scope)
    
        assert(isfield(scope, 'casebank') && isstruct(scope.casebank), ...
            'Stage08.1 scope missing casebank.');
    
        tables = {};
        family_names = {};
    
        if isfield(scope.casebank, 'nominal_table') && istable(scope.casebank.nominal_table)
            tables{end+1} = scope.casebank.nominal_table; %#ok<AGROW>
            family_names{end+1} = 'nominal'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C1_table') && istable(scope.casebank.C1_table)
            tables{end+1} = scope.casebank.C1_table; %#ok<AGROW>
            family_names{end+1} = 'C1'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C2_table') && istable(scope.casebank.C2_table)
            tables{end+1} = scope.casebank.C2_table; %#ok<AGROW>
            family_names{end+1} = 'C2'; %#ok<AGROW>
        end
    
        assert(~isempty(tables), 'No valid family tables found in scope.casebank.');
    
        for i = 1:numel(tables)
            T = tables{i};
            fam = string(family_names{i});
    
            if ~any(strcmp(T.Properties.VariableNames, 'family_name'))
                T.family_name = repmat(fam, height(T), 1);
            else
                T.family_name = string(T.family_name);
            end
    
            if ~any(strcmp(T.Properties.VariableNames, 'sample_type'))
                T.sample_type = repmat(fam, height(T), 1);
            else
                T.sample_type = string(T.sample_type);
            end
    
            tables{i} = T;
        end
    
        casebank_table = local_vertcat_tables_union(tables);
    
        if any(strcmp(casebank_table.Properties.VariableNames, 'entry_id')) && ...
                any(strcmp(casebank_table.Properties.VariableNames, 'heading_deg'))
            casebank_table = sortrows(casebank_table, {'sample_type','entry_id','heading_deg'}, ...
                {'ascend','ascend','ascend'});
        end
    end
    
    
    function Tcat = local_vertcat_tables_union(tables)
    
        all_vars = {};
        for i = 1:numel(tables)
            all_vars = union(all_vars, tables{i}.Properties.VariableNames, 'stable');
        end
    
        Tcat = table();
        for i = 1:numel(tables)
            T = tables{i};
            missing_vars = setdiff(all_vars, T.Properties.VariableNames, 'stable');
    
            for j = 1:numel(missing_vars)
                v = missing_vars{j};
                T.(v) = local_make_missing_column(height(T));
            end
    
            T = T(:, all_vars);
    
            if isempty(Tcat)
                Tcat = T;
            else
                Tcat = [Tcat; T];
            end
        end
    end
    
    
    function c = local_make_missing_column(n)
        c = repmat(missing, n, 1);
    end
    
    
    function case_item = local_build_casebank_case_item(case_row, nominal_bank, cfg)
    
        entry_id = local_get_table_value(case_row, 'entry_id', NaN);
        heading_deg = local_get_table_value(case_row, 'heading_deg', NaN);
        sample_type = string(local_get_table_value(case_row, 'sample_type', "unknown"));
        family_name = string(local_get_table_value(case_row, 'family_name', sample_type));
    
        assert(isfinite(entry_id), 'Case row missing entry_id.');
        assert(isfinite(heading_deg), 'Case row missing heading_deg.');
    
        base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id);
        assert(~isempty(base_item), 'Failed to find nominal Stage02 item for entry_id=%g.', entry_id);
    
        base_case = base_item.case;
        nominal_heading_deg = local_extract_numeric(base_case, 'heading_deg', NaN);
        assert(isfinite(nominal_heading_deg), 'Base nominal case missing heading_deg.');
    
        case_new = base_case;
        case_new.heading_deg = heading_deg;
        case_new.heading_offset_deg = wrapTo180(heading_deg - nominal_heading_deg);
        case_new.nominal_heading_deg = nominal_heading_deg;
        case_new.entry_id = entry_id;
        case_new.entry_point_id = entry_id;
        case_new.family = 'stage08_casebank';
        case_new.subfamily = char(sample_type);
        case_new.source_case_id = char(string(base_case.case_id));
        case_new.sample_type = char(sample_type);
        case_new.family_name = char(family_name);
        case_new.case_id = sprintf('S08S_E%02d_%s_H%03d', round(entry_id), char(sample_type), round(heading_deg));
    
        traj_new = propagate_hgv_case_stage02(case_new, cfg);
        val_new = validate_hgv_trajectory_stage02(traj_new, cfg);
        sum_new = summarize_hgv_case_stage02(case_new, traj_new, val_new);
    
        case_item = struct();
        case_item.case = case_new;
        case_item.traj = traj_new;
        case_item.validation = val_new;
        case_item.summary = sum_new;
    end
    
    
    function base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id)
    
        base_item = [];
    
        for k = 1:numel(nominal_bank)
            item_k = nominal_bank(k);
    
            eid = local_extract_numeric(item_k.case, 'entry_id', NaN);
            if ~isfinite(eid)
                eid = local_parse_entry_id_from_case_id(item_k.case);
            end
    
            if isequaln(eid, entry_id)
                base_item = item_k;
                return;
            end
        end
    end
    
    
    function ref_walker = local_make_ref_from_smallgrid_row(walker_cfg, iCfg, cfg)
    
        ref_walker = struct();
        ref_walker.ref_id = iCfg;
        ref_walker.source_stage = 'stage08_smallgrid';
        ref_walker.selection_rule = 'smallgrid_scan';
    
        ref_walker.h_km = local_get_table_value(walker_cfg, 'h_km', NaN);
        ref_walker.i_deg = local_get_table_value(walker_cfg, 'i_deg', NaN);
        ref_walker.P = local_get_table_value(walker_cfg, 'P', NaN);
        ref_walker.T = local_get_table_value(walker_cfg, 'T', NaN);
        ref_walker.F = local_get_table_value(walker_cfg, 'F', 1);
        ref_walker.Ns = local_get_table_value(walker_cfg, 'Ns', ref_walker.P * ref_walker.T);
    
        if isstruct(cfg) && isfield(cfg, 'stage05') && isfield(cfg.stage05, 'require_D_G_min')
            ref_walker.gamma_req = cfg.stage05.require_D_G_min;
        else
            ref_walker.gamma_req = 1.0;
        end
    end
    
    
    function label = local_make_smallgrid_label(ref_walker, iCfg)
        label = sprintf('G%d_h%.0f_i%.0f_P%dT%d', ...
            iCfg, ref_walker.h_km, ref_walker.i_deg, round(ref_walker.P), round(ref_walker.T));
    end

    function config_bank = local_build_smallgrid_config_bank(smallgrid_table, cfg)
        nCfg = height(smallgrid_table);
        config_bank = repmat(struct( ...
            'walker_cfg', table(), ...
            'ref_walker', struct(), ...
            'gamma_req', NaN, ...
            'cfg_label', ""), nCfg, 1);

        for iCfg = 1:nCfg
            walker_cfg = smallgrid_table(iCfg, :);
            ref_walker = local_make_ref_from_smallgrid_row(walker_cfg, iCfg, cfg);
            config_bank(iCfg).walker_cfg = walker_cfg;
            config_bank(iCfg).ref_walker = ref_walker;
            config_bank(iCfg).gamma_req = local_resolve_gamma_req(ref_walker, cfg);
            config_bank(iCfg).cfg_label = local_make_smallgrid_label(ref_walker, iCfg);
        end
    end
    
    
    function metric = local_evaluate_smallgrid_config_over_casebank(case_items, sample_type, ref_walker, gamma_req, cfg_eval)
    
        nCase = numel(case_items);
    
        lambda_worst = nan(nCase, 1);
        D_G_min = nan(nCase, 1);
        t0_worst = nan(nCase, 1);
        coverage_ratio = nan(nCase, 1);
        mean_angle = nan(nCase, 1);
        pass_geom = false(nCase, 1);
    
        for iCase = 1:nCase
            eval_out = evaluate_critical_case_geometry_stage07( ...
                case_items{iCase}, ref_walker, gamma_req, cfg_eval);
    
            diag_row = eval_out.diag_row;
    
            lambda_worst(iCase) = local_get_diag_value(diag_row, 'lambda_worst', NaN);
            D_G_min(iCase) = local_get_diag_value(diag_row, 'D_G_min', NaN);
            t0_worst(iCase) = local_get_diag_value(diag_row, 't0_worst', NaN);
            coverage_ratio(iCase) = local_get_diag_value(diag_row, 'coverage_ratio_2sat', NaN);
            mean_angle(iCase) = local_get_diag_value(diag_row, 'mean_los_intersection_angle_deg', NaN);
    
            pass_geom(iCase) = isfinite(D_G_min(iCase)) && D_G_min(iCase) >= 1;
        end
    
        metric = struct();
        metric.N_case = nCase;
    
        metric.lambda_worst_mean = mean(lambda_worst, 'omitnan');
        metric.lambda_worst_median = median(lambda_worst, 'omitnan');
        metric.lambda_worst_min = min(lambda_worst, [], 'omitnan');
    
        metric.D_G_mean = mean(D_G_min, 'omitnan');
        metric.D_G_median = median(D_G_min, 'omitnan');
        metric.D_G_min = min(D_G_min, [], 'omitnan');
    
        metric.t0_worst_mean = mean(t0_worst, 'omitnan');
        metric.coverage_ratio_mean = mean(coverage_ratio, 'omitnan');
        metric.mean_angle_mean = mean(mean_angle, 'omitnan');
    
        metric.pass_geom_ratio = mean(double(pass_geom), 'omitnan');
        metric.pass_nominal_ratio = local_family_pass_ratio(pass_geom, sample_type, "nominal");
        metric.pass_C1_ratio = local_family_pass_ratio(pass_geom, sample_type, "C1");
        metric.pass_C2_ratio = local_family_pass_ratio(pass_geom, sample_type, "C2");
    
        req = local_resolve_smallgrid_requirements(cfg_eval);
    
        metric.is_feasible = (metric.D_G_min >= req.require_DG_min) && ...
                             (metric.pass_geom_ratio >= req.require_pass_geom_ratio) && ...
                             (metric.pass_C2_ratio >= req.require_C2_pass_ratio);
    end
    
    
    function x = local_family_pass_ratio(pass_geom, sample_type, fam_name)
        idx = sample_type == fam_name;
        if ~any(idx)
            x = NaN;
            return;
        end
        x = mean(double(pass_geom(idx)), 'omitnan');
    end
    
    
    function row = local_build_smallgrid_raw_row(walker_cfg, ref_walker, iCfg, cfg_label, Tw_s, metric)
    
        row = struct();
    
        row.cfg_id = iCfg;
        row.cfg_label = string(cfg_label);
    
        row.h_km = local_get_table_value(walker_cfg, 'h_km', ref_walker.h_km);
        row.i_deg = local_get_table_value(walker_cfg, 'i_deg', ref_walker.i_deg);
        row.P = local_get_table_value(walker_cfg, 'P', ref_walker.P);
        row.T = local_get_table_value(walker_cfg, 'T', ref_walker.T);
        row.F = local_get_table_value(walker_cfg, 'F', ref_walker.F);
        row.Ns = local_get_table_value(walker_cfg, 'Ns', ref_walker.Ns);
    
        row.Tw_s = Tw_s;
    
        row.N_case = metric.N_case;
        row.lambda_worst_mean = metric.lambda_worst_mean;
        row.lambda_worst_median = metric.lambda_worst_median;
        row.lambda_worst_min = metric.lambda_worst_min;
    
        row.D_G_mean = metric.D_G_mean;
        row.D_G_median = metric.D_G_median;
        row.D_G_min = metric.D_G_min;
    
        row.t0_worst_mean = metric.t0_worst_mean;
        row.coverage_ratio_mean = metric.coverage_ratio_mean;
        row.mean_angle_mean = metric.mean_angle_mean;
    
        row.pass_geom_ratio = metric.pass_geom_ratio;
        row.pass_nominal_ratio = metric.pass_nominal_ratio;
        row.pass_C1_ratio = metric.pass_C1_ratio;
        row.pass_C2_ratio = metric.pass_C2_ratio;
    
        row.is_feasible = metric.is_feasible;
    end
    
    
    function T = local_build_Tw_summary_table(raw_config_table)
    
        Tw_vals = unique(raw_config_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_config_table(raw_config_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible == true, :);
            num_feasible = height(feasible_sub);
    
            r = struct();
            r.Tw_s = Tw;
            r.num_config = height(sub);
            r.num_feasible = num_feasible;
            r.feasible_ratio = num_feasible / max(1, height(sub));
    
            if num_feasible >= 1
                Ns_feasible = feasible_sub.Ns;
                r.N_min = min(Ns_feasible, [], 'omitnan');
    
                best_mask = feasible_sub.Ns == r.N_min;
                best_sub = feasible_sub(best_mask, :);
                [~, idx_best] = max(best_sub.D_G_median);
                best_row = best_sub(idx_best, :);
    
                r.best_cfg_id = best_row.cfg_id;
                r.best_cfg_label = best_row.cfg_label;
                r.best_h_km = best_row.h_km;
                r.best_i_deg = best_row.i_deg;
                r.best_P = best_row.P;
                r.best_T = best_row.T;
                r.best_Ns = best_row.Ns;
    
                r.best_D_G_median = best_row.D_G_median;
                r.best_D_G_min = best_row.D_G_min;
                r.best_pass_geom_ratio = best_row.pass_geom_ratio;
                r.best_pass_C2_ratio = best_row.pass_C2_ratio;
            else
                r.N_min = NaN;
                r.best_cfg_id = NaN;
                r.best_cfg_label = "";
                r.best_h_km = NaN;
                r.best_i_deg = NaN;
                r.best_P = NaN;
                r.best_T = NaN;
                r.best_Ns = NaN;
                r.best_D_G_median = NaN;
                r.best_D_G_min = NaN;
                r.best_pass_geom_ratio = NaN;
                r.best_pass_C2_ratio = NaN;
            end
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    function T = local_build_best_config_table(raw_config_table)
    
        Tw_vals = unique(raw_config_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_config_table(raw_config_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible == true, :);
    
            if isempty(feasible_sub)
                feasible_sub = sortrows(sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                feasible_flag = false;
            else
                feasible_sub = sortrows(feasible_sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                feasible_flag = true;
            end
    
            r = struct();
            r.Tw_s = Tw;
            r.best_is_feasible = feasible_flag;
            r.cfg_id = best_row.cfg_id;
            r.cfg_label = best_row.cfg_label;
            r.h_km = best_row.h_km;
            r.i_deg = best_row.i_deg;
            r.P = best_row.P;
            r.T = best_row.T;
            r.F = best_row.F;
            r.Ns = best_row.Ns;
            r.D_G_median = best_row.D_G_median;
            r.D_G_min = best_row.D_G_min;
            r.pass_geom_ratio = best_row.pass_geom_ratio;
            r.pass_nominal_ratio = best_row.pass_nominal_ratio;
            r.pass_C1_ratio = best_row.pass_C1_ratio;
            r.pass_C2_ratio = best_row.pass_C2_ratio;
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    function fig = local_plot_Tw_summary(Tw_summary_table, metric_name, y_label_str)
    
        fig = figure('Color', 'w', 'Position', [120 120 900 520]);
        hold on; grid on; box on;
    
        plot(Tw_summary_table.Tw_s, Tw_summary_table.(metric_name), '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 6);
    
        xlabel('Tw (s)');
        ylabel(y_label_str);
        title(sprintf('Stage08.4 summary: %s', metric_name), 'Interpreter', 'none');
    end
    
    
    function fig = local_plot_best_config_metric(best_config_table, metric_name, y_label_str)
    
        fig = figure('Color', 'w', 'Position', [120 120 900 520]);
        hold on; grid on; box on;
    
        plot(best_config_table.Tw_s, best_config_table.(metric_name), '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 6);
    
        xlabel('Tw (s)');
        ylabel(y_label_str);
        title(sprintf('Stage08.4 best-config curve: %s', metric_name), 'Interpreter', 'none');
    end
    
    
    function gamma_req = local_resolve_gamma_req(ref_walker, cfg)
    
        gamma_req = local_get_struct_value(ref_walker, 'gamma_req', NaN);
        if isfinite(gamma_req)
            return;
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage04') && isstruct(cfg.stage04) && ...
                isfield(cfg.stage04, 'gamma_req') && ~isempty(cfg.stage04.gamma_req)
            gamma_req = cfg.stage04.gamma_req;
            if isfinite(gamma_req)
                return;
            end
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage05') && isstruct(cfg.stage05) && ...
                isfield(cfg.stage05, 'require_D_G_min') && ~isempty(cfg.stage05.require_D_G_min)
            gamma_req = cfg.stage05.require_D_G_min;
            if isfinite(gamma_req)
                return;
            end
        end
    
        gamma_req = 1.0;
    end
    
    
    function req = local_resolve_smallgrid_requirements(cfg)

        % default profile
        profile = "medium";
    
        if isstruct(cfg) && isfield(cfg, 'stage08') && isstruct(cfg.stage08) && ...
                isfield(cfg.stage08, 'smallgrid') && isstruct(cfg.stage08.smallgrid) && ...
                isfield(cfg.stage08.smallgrid, 'feasibility_profile') && ...
                ~isempty(cfg.stage08.smallgrid.feasibility_profile)
            profile = string(cfg.stage08.smallgrid.feasibility_profile);
        end
    
        switch lower(profile)
            case "relaxed"
                req.require_DG_min = 1.0;
                req.require_pass_geom_ratio = 0.90;
                req.require_C2_pass_ratio = 0.50;
    
            case "medium"
                req.require_DG_min = 1.0;
                req.require_pass_geom_ratio = 1.00;
                req.require_C2_pass_ratio = 0.75;
    
            case "strict"
                req.require_DG_min = 1.2;
                req.require_pass_geom_ratio = 1.00;
                req.require_C2_pass_ratio = 1.00;
    
            otherwise
                error('Unknown cfg.stage08.smallgrid.feasibility_profile: %s', profile);
        end
    end
    
    
    function value = local_get_table_value(Trow, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if istable(Trow) && height(Trow) >= 1 && any(strcmp(Trow.Properties.VariableNames, field_name))
            tmp = Trow.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function value = local_get_struct_value(S, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(S) && isfield(S, field_name)
            tmp = S.(field_name);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function value = local_get_diag_value(diag_row, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(diag_row)
            value = local_get_struct_value(diag_row, field_name, default_value);
            return;
        end
    
        if istable(diag_row) && height(diag_row) >= 1 && any(strcmp(diag_row.Properties.VariableNames, field_name))
            tmp = diag_row.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function x = local_extract_numeric(S, field_name, fallback)
        x = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if isnumeric(val) && ~isempty(val) && isfinite(val(1))
                x = double(val(1));
            end
        end
    end
    
    
    function entry_id = local_parse_entry_id_from_case_id(base_case)
        entry_id = NaN;
        if isstruct(base_case) && isfield(base_case, 'case_id') && ~isempty(base_case.case_id)
            cid = char(string(base_case.case_id));
            tok = regexp(cid, '^N(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                entry_id = str2double(tok{1});
            end
        end
    end

    function cfg = local_apply_stage08_opts(cfg, opts)
        if isfield(opts, 'mode') && ~isempty(opts.mode)
            cfg.stage08.smallgrid.use_parallel = strcmpi(string(opts.mode), "parallel");
        end

        if isfield(opts, 'parallel_config') && isstruct(opts.parallel_config)
            if isfield(opts.parallel_config, 'num_workers') && ~isempty(opts.parallel_config.num_workers)
                cfg.stage08.smallgrid.max_workers = opts.parallel_config.num_workers;
            end
        end

        if isfield(opts, 'disable_progress') && ~isempty(opts.disable_progress)
            cfg.stage08.smallgrid.disable_progress = logical(opts.disable_progress);
        end
        if isfield(opts, 'benchmark_mode') && opts.benchmark_mode
            cfg.stage08.smallgrid.make_plot = false;
        end
    end

    function [scope, cfg] = local_apply_smallgrid_scope_overrides(scope, cfg, opts)
        if isfield(opts, 'benchmark_smallgrid_max_config_count') && ~isempty(opts.benchmark_smallgrid_max_config_count)
            n_cfg = min(height(scope.smallgrid_table), opts.benchmark_smallgrid_max_config_count);
            scope.smallgrid_table = scope.smallgrid_table(1:n_cfg, :);
        end

        if isfield(opts, 'benchmark_smallgrid_max_tw_count') && ~isempty(opts.benchmark_smallgrid_max_tw_count)
            n_tw = min(numel(scope.Tw_grid_s), opts.benchmark_smallgrid_max_tw_count);
            scope.Tw_grid_s = scope.Tw_grid_s(1:n_tw);
        end
    end
