function out = stage08_boundary_window_sensitivity(cfg, opts)
    %STAGE08_BOUNDARY_WINDOW_SENSITIVITY
    % Stage08.4c:
    %   Boundary-driven window sensitivity analysis using
    %   1) hard-case bank
    %   2) weak-side small-grid
    %   3) tail-based feasibility rule
    %
    % Main outputs:
    %   out.hardcase_table
    %   out.weakside_smallgrid_table
    %   out.raw_boundary_scan_table
    %   out.Tw_summary_table
    %   out.best_config_table
    %   out.flip_table
    %   out.dominant_hardcase_table
    %   out.figures
    %   out.files
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2 || isempty(opts)
            opts = struct();
        end
        cfg = local_prepare_stage08c_cfg(cfg);
        cfg = local_apply_stage08c_opts(cfg, opts);
        cfg.project_stage = 'stage08_boundary_window_sensitivity';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_boundary_window_sensitivity_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.4c started.');
    
        % ============================================================
        % Load caches
        % ============================================================
        [scope_base, nominal_bank, risk_table, selection_table, stage08_scope_file, ...
            stage02_file, stage07_risk_file, stage07_sel_file] = local_load_stage08c_inputs(cfg, run_tag);
        log_msg(log_fid, 'INFO', 'Loaded Stage08.1 scope: %s', stage08_scope_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage02 nominal cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage07.3 risk map: %s', stage07_risk_file);
        log_msg(log_fid, 'INFO', 'Stage07.3 risk rows = %d', height(risk_table));
        log_msg(log_fid, 'INFO', 'Loaded Stage07.4 selected examples: %s', stage07_sel_file);
        log_msg(log_fid, 'INFO', 'Stage07.4 selection rows = %d', height(selection_table));

        scope = local_apply_stage08c_scope_overrides(scope_base, opts);
        Tw_grid_s = scope.Tw_grid_s(:).';
        log_msg(log_fid, 'INFO', 'Tw grid = %s', mat2str(Tw_grid_s));

        % ============================================================
        % Build workset
        % ============================================================
        [hardcase_table, weakside_smallgrid_table, hardcase_items, task_table, config_bank, hardcase_bank] = ...
            local_prepare_stage08c_workset(selection_table, risk_table, nominal_bank, Tw_grid_s, ...
            cfg, stage08_scope_file, stage02_file, stage07_risk_file, stage07_sel_file);
        log_msg(log_fid, 'INFO', 'Hard-case bank rows = %d', height(hardcase_table));
        log_msg(log_fid, 'INFO', 'Weak-side small-grid rows = %d', height(weakside_smallgrid_table));
        log_msg(log_fid, 'INFO', 'Prebuilt hard-case items = %d', numel(hardcase_items));

        nTask = height(task_table);
        log_msg(log_fid, 'INFO', 'Task count = %d', nTask);
    
        % ============================================================
        % Parallel pool + progress
        % ============================================================
        pool_info = local_ensure_parallel_pool_stage08c(cfg, log_fid);
        use_parallel = pool_info.use_parallel;
    
        tStart = tic;
        nComplete = 0;
        progress_step = cfg.stage08c.progress_step;
    
        disable_progress = cfg.stage08c.disable_progress;
        if use_parallel && ~disable_progress
            q = parallel.pool.DataQueue;
            afterEach(q, @progressCallback);
        else
            q = [];
        end
    
        % ============================================================
        % Main scan: one task = one (config, Tw)
        % ============================================================
        raw_task_rows = cell(nTask, 1);
        raw_case_tables = cell(nTask, 1);
        dominant_rows = cell(nTask, 1);
    
        if use_parallel
            parfor iTask = 1:nTask
                [raw_task_rows{iTask}, raw_case_tables{iTask}, dominant_rows{iTask}] = ...
                    local_run_boundary_task(task_table(iTask, :), config_bank, ...
                    hardcase_table, hardcase_bank, hardcase_items, cfg, q);
            end
        else
            for iTask = 1:nTask
                [raw_task_rows{iTask}, raw_case_tables{iTask}, dominant_rows{iTask}] = ...
                    local_run_boundary_task(task_table(iTask, :), config_bank, ...
                    hardcase_table, hardcase_bank, hardcase_items, cfg, []);
                if ~disable_progress
                    progressCallback(local_make_progress_msg_from_taskrow(raw_task_rows{iTask}));
                end
            end
        end
    
        raw_boundary_scan_table = struct2table(vertcat(raw_task_rows{:}));
        raw_case_scan_table = vertcat(raw_case_tables{:});
        dominant_hardcase_table = struct2table(vertcat(dominant_rows{:}));
    
        % ============================================================
        % Summaries
        % ============================================================
        Tw_summary_table = local_build_Tw_summary_table_stage08c(raw_boundary_scan_table);
        best_config_table = local_build_best_config_table_stage08c(raw_boundary_scan_table);
        flip_table = local_build_flip_table_stage08c(raw_boundary_scan_table);
        Tw_summary_table = local_attach_flip_count_stage08c(Tw_summary_table, flip_table);
            
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.Nmin_vs_Tw = '';
        figures.num_feasible_vs_Tw = '';
        figures.feasible_ratio_vs_Tw = '';
        figures.best_DGmedian_vs_Tw = '';
        figures.flip_count_vs_Tw = '';
        figures.feasibility_heatmap = '';
    
        if cfg.stage08c.make_plot
            fig1 = local_plot_scalar_vs_Tw(Tw_summary_table, 'N_min', 'N_{min}', ...
                'Stage08.4c summary: N_{min}');
            figures.Nmin_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_Nmin_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.Nmin_vs_Tw, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_scalar_vs_Tw(Tw_summary_table, 'num_feasible', 'num feasible', ...
                'Stage08.4c summary: num feasible');
            figures.num_feasible_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_num_feasible_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.num_feasible_vs_Tw, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_scalar_vs_Tw(Tw_summary_table, 'feasible_ratio', 'feasible ratio', ...
                'Stage08.4c summary: feasible ratio');
            figures.feasible_ratio_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_feasible_ratio_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.feasible_ratio_vs_Tw, 'Resolution', 180);
            close(fig3);
    
            fig4 = local_plot_scalar_vs_Tw(Tw_summary_table, 'best_DG_median', 'best D_G median', ...
                'Stage08.4c summary: best D_G median');
            figures.best_DGmedian_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_best_DGmedian_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig4, figures.best_DGmedian_vs_Tw, 'Resolution', 180);
            close(fig4);
    
            fig5 = local_plot_scalar_vs_Tw(Tw_summary_table, 'flip_count', 'flip count', ...
                'Stage08.4c summary: flip count');
            figures.flip_count_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_flip_count_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig5, figures.flip_count_vs_Tw, 'Resolution', 180);
            close(fig5);
    
            fig6 = local_plot_feasibility_heatmap(raw_boundary_scan_table);
            figures.feasibility_heatmap = fullfile(cfg.paths.figs, ...
                sprintf('stage08c_feasibility_heatmap_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig6, figures.feasibility_heatmap, 'Resolution', 180);
            close(fig6);
        end
    
        % ============================================================
        % Save CSVs
        % ============================================================
        hardcase_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_hardcase_table_%s_%s.csv', run_tag, timestamp));
        smallgrid_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_weakside_smallgrid_%s_%s.csv', run_tag, timestamp));
        raw_task_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_raw_boundary_scan_%s_%s.csv', run_tag, timestamp));
        raw_case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_raw_case_scan_%s_%s.csv', run_tag, timestamp));
        Tw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_Tw_summary_%s_%s.csv', run_tag, timestamp));
        best_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_best_config_%s_%s.csv', run_tag, timestamp));
        flip_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_flip_table_%s_%s.csv', run_tag, timestamp));
        dominant_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_dominant_hardcase_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08c_summary_%s_%s.csv', run_tag, timestamp));
    
        if ~cfg.stage08c.benchmark_mode
            writetable(hardcase_table, hardcase_csv);
            writetable(weakside_smallgrid_table, smallgrid_csv);
            writetable(raw_boundary_scan_table, raw_task_csv);
            writetable(raw_case_scan_table, raw_case_csv);
            writetable(Tw_summary_table, Tw_csv);
            writetable(best_config_table, best_csv);
            writetable(flip_table, flip_csv);
            writetable(dominant_hardcase_table, dominant_csv);
        else
            hardcase_csv = '';
            smallgrid_csv = '';
            raw_task_csv = '';
            raw_case_csv = '';
            Tw_csv = '';
            best_csv = '';
            flip_csv = '';
            dominant_csv = '';
        end
    
        summary_table = table( ...
            string(stage08_scope_file), ...
            string(stage02_file), ...
            string(stage07_risk_file), ...
            string(stage07_sel_file), ...
            height(hardcase_table), ...
            height(weakside_smallgrid_table), ...
            numel(Tw_grid_s), ...
            height(raw_boundary_scan_table), ...
            height(raw_case_scan_table), ...
            height(flip_table), ...
            use_parallel, ...
            pool_info.num_workers, ...
            toc(tStart), ...
            'VariableNames', { ...
                'stage08_scope_file', ...
                'stage02_file', ...
                'stage07_risk_file', ...
                'stage07_sel_file', ...
                'n_hardcase', ...
                'n_weakside_grid', ...
                'n_Tw', ...
                'n_raw_boundary_row', ...
                'n_raw_case_row', ...
                'n_flip_row', ...
                'used_parallel', ...
                'num_workers', ...
                'elapsed_seconds'});
    
        if ~cfg.stage08c.benchmark_mode
            writetable(summary_table, summary_csv);
        else
            summary_csv = '';
        end
    
        % ============================================================
        % Save MAT
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.hardcase_table = hardcase_table;
        out.weakside_smallgrid_table = weakside_smallgrid_table;
        out.raw_boundary_scan_table = raw_boundary_scan_table;
        out.raw_case_scan_table = raw_case_scan_table;
        out.Tw_summary_table = Tw_summary_table;
        out.best_config_table = best_config_table;
        out.flip_table = flip_table;
        out.dominant_hardcase_table = dominant_hardcase_table;
        out.figures = figures;
        out.summary_table = summary_table;
        out.pool_info = pool_info;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.hardcase_csv = hardcase_csv;
        out.files.smallgrid_csv = smallgrid_csv;
        out.files.raw_task_csv = raw_task_csv;
        out.files.raw_case_csv = raw_case_csv;
        out.files.Tw_csv = Tw_csv;
        out.files.best_csv = best_csv;
        out.files.flip_csv = flip_csv;
        out.files.dominant_csv = dominant_csv;
        out.files.summary_csv = summary_csv;
    
        if ~cfg.stage08c.benchmark_mode
            cache_file = fullfile(cfg.paths.cache, ...
                sprintf('stage08_boundary_window_sensitivity_%s_%s.mat', run_tag, timestamp));
            save(cache_file, 'out', '-v7.3');
            out.files.cache_file = cache_file;
            log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        else
            cache_file = '';
            out.files.cache_file = '';
        end
        log_msg(log_fid, 'INFO', 'Stage08.4c finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.4c Summary ==========\n');
        fprintf('Hard cases           : %d\n', height(hardcase_table));
        fprintf('Weak-side configs    : %d\n', height(weakside_smallgrid_table));
        fprintf('Tw count             : %d\n', numel(Tw_grid_s));
        fprintf('Raw boundary rows    : %d\n', height(raw_boundary_scan_table));
        fprintf('Raw case rows        : %d\n', height(raw_case_scan_table));
        fprintf('Flip rows            : %d\n', height(flip_table));
        fprintf('Used parallel        : %d\n', use_parallel);
        fprintf('Worker count         : %d\n', pool_info.num_workers);
        fprintf('Elapsed seconds      : %.1f\n', toc(tStart));
        fprintf('Cache                : %s\n', cache_file);
        fprintf('========================================\n');
    
        function progressCallback(msg)
            nComplete = nComplete + 1;
            do_print = (mod(nComplete, progress_step) == 0) || (nComplete == 1) || (nComplete == nTask);
            if do_print
                elapsed_s = toc(tStart);
                line = sprintf(['Progress %3d/%3d | cfg=%2d | Tw=%6.1f s | feasible=%d | ', ...
                                'DGtail=%.3f | DGc2=%.3f | DGmed=%.3f | elapsed=%.1f s'], ...
                    nComplete, nTask, msg.cfg_id, msg.Tw_s, msg.is_feasible_boundary, ...
                    msg.tail_hard_min, msg.tail_C2_min, msg.D_G_median, elapsed_s);
                fprintf('%s\n', line);
                log_msg(log_fid, 'INFO', '%s', line);
            end
        end
    end
    
    
    % ============================================================
    % config + loading helpers
    % ============================================================
    
    function cfg = local_prepare_stage08c_cfg(cfg)
    
        if ~isfield(cfg, 'stage08c') || ~isstruct(cfg.stage08c)
            cfg.stage08c = struct();
        end
    
        f = cfg.stage08c;
    
        if ~isfield(f, 'n_hard_nominal'), f.n_hard_nominal = 3; end
        if ~isfield(f, 'n_hard_C1'), f.n_hard_C1 = 3; end
        if ~isfield(f, 'n_hard_C2'), f.n_hard_C2 = 6; end
    
        if ~isfield(f, 'h_km_list') || isempty(f.h_km_list), f.h_km_list = 1000; end
        if ~isfield(f, 'i_deg_list') || isempty(f.i_deg_list), f.i_deg_list = [50, 60]; end
        if ~isfield(f, 'PT_pairs') || isempty(f.PT_pairs)
            f.PT_pairs = [8,4;8,5;8,6;10,4;10,5;12,4;12,5;14,4;16,4];
        end
        if ~isfield(f, 'F') || isempty(f.F), f.F = 1; end
    
        if ~isfield(f, 'tail_hard_k') || isempty(f.tail_hard_k), f.tail_hard_k = 3; end
        if ~isfield(f, 'tail_C2_k') || isempty(f.tail_C2_k), f.tail_C2_k = 2; end
        if ~isfield(f, 'require_DG_min') || isempty(f.require_DG_min), f.require_DG_min = 1.0; end
    
        if ~isfield(f, 'use_parallel') || isempty(f.use_parallel), f.use_parallel = true; end
        if ~isfield(f, 'max_workers') || isempty(f.max_workers), f.max_workers = inf; end
        if ~isfield(f, 'progress_step') || isempty(f.progress_step), f.progress_step = 1; end
        if ~isfield(f, 'disable_progress') || isempty(f.disable_progress), f.disable_progress = false; end
        if ~isfield(f, 'prefer_thread_pool_for_batch') || isempty(f.prefer_thread_pool_for_batch), f.prefer_thread_pool_for_batch = true; end
        if ~isfield(f, 'benchmark_mode') || isempty(f.benchmark_mode), f.benchmark_mode = false; end

        if ~isfield(f, 'make_plot') || isempty(f.make_plot), f.make_plot = true; end

        cfg.stage08c = f;
    end


    function cfg = local_apply_stage08c_opts(cfg, opts)

        if isfield(opts, 'mode') && ~isempty(opts.mode)
            cfg.stage08c.use_parallel = strcmpi(string(opts.mode), "parallel");
        end

        if isfield(opts, 'parallel_config') && isstruct(opts.parallel_config)
            if isfield(opts.parallel_config, 'num_workers') && ~isempty(opts.parallel_config.num_workers)
                cfg.stage08c.max_workers = opts.parallel_config.num_workers;
            end
        end

        if isfield(opts, 'disable_progress') && ~isempty(opts.disable_progress)
            cfg.stage08c.disable_progress = logical(opts.disable_progress);
        end

        if isfield(opts, 'benchmark_mode') && logical(opts.benchmark_mode)
            cfg.stage08c.make_plot = false;
            cfg.stage08c.disable_progress = true;
            cfg.stage08c.benchmark_mode = true;
        end

        if isfield(opts, 'benchmark_h_km_list') && ~isempty(opts.benchmark_h_km_list)
            cfg.stage08c.h_km_list = opts.benchmark_h_km_list;
        end
        if isfield(opts, 'benchmark_i_deg_list') && ~isempty(opts.benchmark_i_deg_list)
            cfg.stage08c.i_deg_list = opts.benchmark_i_deg_list;
        end
        if isfield(opts, 'benchmark_PT_pairs') && ~isempty(opts.benchmark_PT_pairs)
            cfg.stage08c.PT_pairs = opts.benchmark_PT_pairs;
        end
    end


    function scope = local_apply_stage08c_scope_overrides(scope, opts)

        if isfield(opts, 'benchmark_max_tw_count') && ~isempty(opts.benchmark_max_tw_count)
            n_tw = min(numel(scope.Tw_grid_s), opts.benchmark_max_tw_count);
            scope.Tw_grid_s = scope.Tw_grid_s(1:n_tw);
        end
    end
    
    
    function cache_file = local_find_latest_cache(cache_dir, pattern)
        d = dir(fullfile(cache_dir, pattern));
        assert(~isempty(d), 'No cache matched pattern: %s', pattern);
        [~, idx] = max([d.datenum]);
        cache_file = fullfile(d(idx).folder, d(idx).name);
    end


    function [scope, nominal_bank, risk_table, selection_table, stage08_scope_file, ...
            stage02_file, stage07_risk_file, stage07_sel_file] = local_load_stage08c_inputs(cfg, run_tag)
        persistent cache

        stage08_scope_file = local_find_latest_cache(cfg.paths.cache, ...
            sprintf('stage08_define_window_scope_%s_*.mat', run_tag));
        stage02_file = local_find_latest_cache(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        stage07_risk_file = local_find_latest_stage07_cache( ...
            cfg.paths.cache, 'stage07_scan_heading_risk_map', cfg);
        stage07_sel_file = local_find_latest_stage07_cache( ...
            cfg.paths.cache, 'stage07_select_critical_examples', cfg);

        cache_key = sprintf('%s|%s|%s|%s', stage08_scope_file, stage02_file, stage07_risk_file, stage07_sel_file);
        cache_hit = isstruct(cache) && isfield(cache, 'key') && strcmp(cache.key, cache_key);

        if ~cache_hit
            S81 = load(stage08_scope_file);
            assert(isfield(S81, 'out') && isfield(S81.out, 'scope'), ...
                'Invalid Stage08.1 cache: missing out.scope');
            S2 = load(stage02_file);
            assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
                'Invalid Stage02 cache: missing out.trajbank.nominal');
            S73 = load(stage07_risk_file);
            risk_table = local_extract_first_table(S73);
            assert(istable(risk_table) && ~isempty(risk_table), ...
                'Failed to resolve Stage07.3 risk table.');
            S74 = load(stage07_sel_file);
            selection_table = local_extract_selection_table(S74);
            assert(istable(selection_table) && ~isempty(selection_table), ...
                'Failed to resolve Stage07.4 selection table.');

            cache = struct();
            cache.key = cache_key;
            cache.scope = S81.out.scope;
            cache.nominal_bank = S2.out.trajbank.nominal;
            cache.risk_table = risk_table;
            cache.selection_table = selection_table;
        end

        scope = cache.scope;
        nominal_bank = cache.nominal_bank;
        risk_table = cache.risk_table;
        selection_table = cache.selection_table;
    end
    
    
    function T = local_extract_first_table(S)
        T = table();
        names = fieldnames(S);
        for i = 1:numel(names)
            v = S.(names{i});
            if istable(v)
                T = v;
                return;
            end
            if isstruct(v)
                subnames = fieldnames(v);
                for j = 1:numel(subnames)
                    subv = v.(subnames{j});
                    if istable(subv)
                        T = subv;
                        return;
                    end
                end
            end
        end
    end
    
    
    function T = local_extract_selection_table(S)
        T = table();
    
        % common patterns
        if isfield(S, 'out') && isstruct(S.out)
            if isfield(S.out, 'selection_table') && istable(S.out.selection_table)
                T = S.out.selection_table;
                return;
            end
            if isfield(S.out, 'selected_table') && istable(S.out.selected_table)
                T = S.out.selected_table;
                return;
            end
            if isfield(S.out, 'summary') && isstruct(S.out.summary)
                fn = fieldnames(S.out.summary);
                for i = 1:numel(fn)
                    if istable(S.out.summary.(fn{i}))
                        T = S.out.summary.(fn{i});
                        return;
                    end
                end
            end
        end
    
        T = local_extract_first_table(S);
    end
    
    
    function pool_info = local_ensure_parallel_pool_stage08c(cfg, log_fid)
    
        pool_info = struct();
        pool_info.use_parallel = false;
        pool_info.num_workers = 0;
    
        if ~cfg.stage08c.use_parallel
            log_msg(log_fid, 'INFO', 'Parallel disabled by cfg.stage08c.use_parallel=false.');
            return;
        end
    
        try
            p = gcp('nocreate');
            if isempty(p)
                prefer_threads = isfield(cfg.stage08c, 'prefer_thread_pool_for_batch') && ...
                    cfg.stage08c.prefer_thread_pool_for_batch && cfg.stage08c.disable_progress;
                if prefer_threads
                    if isfinite(cfg.stage08c.max_workers)
                        p = parpool('threads', min(feature('numcores'), cfg.stage08c.max_workers));
                    else
                        p = parpool('threads');
                    end
                elseif isfinite(cfg.stage08c.max_workers)
                    p = parpool(min(feature('numcores'), cfg.stage08c.max_workers));
                else
                    p = parpool;
                end
            end
            pool_info.use_parallel = true;
            pool_info.num_workers = p.NumWorkers;
            log_msg(log_fid, 'INFO', 'Parallel pool ready. workers = %d', p.NumWorkers);
        catch ME
            pool_info.use_parallel = false;
            log_msg(log_fid, 'INFO', 'Parallel unavailable. Fallback to serial. Reason: %s', ME.message);
        end
    end
    
    
    % ============================================================
    % hard-case bank + weak-side grid
    % ============================================================
    
    function hardcase_table = local_build_hardcase_table(selection_table, risk_table, cfg)
    
        T = local_unify_case_table([selection_table; local_align_like(selection_table, risk_table)]);
        assert(~isempty(T), 'Failed to build unified candidate case table.');
    
        T.family_name = local_get_family_col(T);
        T.entry_id = local_get_numeric_col(T, {'entry_id','entry_point_id'}, NaN);
        T.heading_deg = local_get_numeric_col(T, {'heading_deg'}, NaN);
        T.D_G_min = local_get_numeric_col(T, {'D_G_min','DG_min'}, NaN);
        T.lambda_worst = local_get_numeric_col(T, {'lambda_worst'}, NaN);
        T.t0_worst = local_get_numeric_col(T, {'t0_worst'}, NaN);
        T.coverage_ratio_2sat = local_get_numeric_col(T, {'coverage_ratio_2sat'}, NaN);
        T.mean_los_intersection_angle_deg = local_get_numeric_col(T, ...
            {'mean_los_intersection_angle_deg','mean_los_angle_deg'}, NaN);
    
        T = T(isfinite(T.entry_id) & isfinite(T.heading_deg) & isfinite(T.D_G_min), :);
    
        Hn = local_pick_hardcases_family(T, "nominal", cfg.stage08c.n_hard_nominal);
        H1 = local_pick_hardcases_family(T, "C1", cfg.stage08c.n_hard_C1);
        H2 = local_pick_hardcases_family(T, "C2", cfg.stage08c.n_hard_C2);
    
        H = [Hn; H1; H2];
        H = sortrows(H, {'family_name','D_G_min','lambda_worst'}, {'ascend','ascend','ascend'});
    
        H.hard_id = (1:height(H)).';
        H.hard_rank = (1:height(H)).';
    
        keep = {'hard_id','hard_rank','family_name','entry_id','heading_deg', ...
            'D_G_min','lambda_worst','t0_worst','coverage_ratio_2sat', ...
            'mean_los_intersection_angle_deg'};
        keep = keep(ismember(keep, H.Properties.VariableNames));
        hardcase_table = H(:, keep);
    end
    
    
    function H = local_pick_hardcases_family(T, fam, n_pick)

        sub = T(T.family_name == fam, :);
        if isempty(sub)
            H = sub;
            return;
        end
    
        sub = sortrows(sub, {'D_G_min','lambda_worst','mean_los_intersection_angle_deg'}, ...
            {'ascend','ascend','ascend'});
    
        % family-specific dedup
        if fam == "C2"
            key = strcat(string(sub.entry_id), "_", string(round(sub.heading_deg)));
        else
            key = string(sub.entry_id);
        end
    
        [~, ia] = unique(key, 'stable');
        sub = sub(sort(ia), :);
    
        H = sub(1:min(n_pick, height(sub)), :);
    end


    function [hardcase_table, weakside_smallgrid_table, hardcase_items, task_table, config_bank, hardcase_bank] = ...
            local_prepare_stage08c_workset(selection_table, risk_table, nominal_bank, Tw_grid_s, ...
            cfg, stage08_scope_file, stage02_file, stage07_risk_file, stage07_sel_file)
        persistent cache

        key = sprintf('%s|%s|%s|%s|Tw%s|h%s|i%s|pt%s|nh%d|n1%d|n2%d', ...
            stage08_scope_file, stage02_file, stage07_risk_file, stage07_sel_file, ...
            mat2str(Tw_grid_s), mat2str(cfg.stage08c.h_km_list), mat2str(cfg.stage08c.i_deg_list), ...
            mat2str(cfg.stage08c.PT_pairs), cfg.stage08c.n_hard_nominal, ...
            cfg.stage08c.n_hard_C1, cfg.stage08c.n_hard_C2);
        cache_hit = isstruct(cache) && isfield(cache, 'key') && strcmp(cache.key, key);

        if ~cache_hit
            hardcase_table = local_build_hardcase_table(selection_table, risk_table, cfg);
            weakside_smallgrid_table = local_build_weakside_smallgrid_table(cfg);
            task_table = local_build_task_table(weakside_smallgrid_table, Tw_grid_s);
            config_bank = local_build_stage08c_config_bank(weakside_smallgrid_table, cfg);
            hardcase_bank = local_build_stage08c_hardcase_bank(hardcase_table);
            hardcase_items = cell(height(hardcase_table), 1);
            for iHard = 1:height(hardcase_table)
                hardcase_items{iHard} = local_build_case_item_from_row(hardcase_table(iHard, :), nominal_bank, cfg, 'S08C');
            end

            cache = struct();
            cache.key = key;
            cache.hardcase_table = hardcase_table;
            cache.weakside_smallgrid_table = weakside_smallgrid_table;
            cache.hardcase_items = hardcase_items;
            cache.task_table = task_table;
            cache.config_bank = config_bank;
            cache.hardcase_bank = hardcase_bank;
        end

        hardcase_table = cache.hardcase_table;
        weakside_smallgrid_table = cache.weakside_smallgrid_table;
        hardcase_items = cache.hardcase_items;
        task_table = cache.task_table;
        config_bank = cache.config_bank;
        hardcase_bank = cache.hardcase_bank;
    end
    
    
    function smallgrid = local_build_weakside_smallgrid_table(cfg)
    
        h_list = cfg.stage08c.h_km_list(:);
        i_list = cfg.stage08c.i_deg_list(:);
        PT = cfg.stage08c.PT_pairs;
        F = cfg.stage08c.F;
    
        rows = cell(numel(h_list) * numel(i_list) * size(PT,1), 1);
        ptr = 0;
        for ih = 1:numel(h_list)
            for ii = 1:numel(i_list)
                for ip = 1:size(PT,1)
                    ptr = ptr + 1;
                    P = PT(ip,1);
                    T = PT(ip,2);
    
                    r = struct();
                    r.cfg_id = ptr;
                    r.h_km = h_list(ih);
                    r.i_deg = i_list(ii);
                    r.P = P;
                    r.T = T;
                    r.F = F;
                    r.Ns = P * T;
                    r.grid_family = "weakside";
                    rows{ptr} = r;
                end
            end
        end
    
        smallgrid = struct2table(vertcat(rows{:}));
        smallgrid = sortrows(smallgrid, {'Ns','i_deg','h_km'}, {'ascend','ascend','ascend'});
        smallgrid.cfg_id = (1:height(smallgrid)).';
    end
    
    
    function Tout = local_align_like(Tref, Tin)
    
        if isempty(Tref)
            Tout = Tin;
            return;
        end
        if isempty(Tin)
            Tout = Tref([], :);
            return;
        end
    
        vars_ref = Tref.Properties.VariableNames;
        vars_in = Tin.Properties.VariableNames;
        missing = setdiff(vars_ref, vars_in, 'stable');
        for i = 1:numel(missing)
            Tin.(missing{i}) = local_make_missing_column(height(Tin));
        end
        extra = setdiff(vars_in, vars_ref, 'stable');
        vars_all = [vars_ref, extra];
        missing2 = setdiff(vars_all, Tin.Properties.VariableNames, 'stable');
        for i = 1:numel(missing2)
            Tin.(missing2{i}) = local_make_missing_column(height(Tin));
        end
        Tout = Tin(:, vars_all);
    end
    
    
    function T = local_unify_case_table(T)
    
        if isempty(T)
            return;
        end
    
        if ~any(strcmp(T.Properties.VariableNames, 'family_name'))
            T.family_name = local_get_family_col(T);
        else
            T.family_name = string(T.family_name);
        end
    
        if ~any(strcmp(T.Properties.VariableNames, 'entry_id'))
            T.entry_id = local_get_numeric_col(T, {'entry_point_id'}, NaN);
        end
    end
    
    
    % ============================================================
    % task building + case reconstruction
    % ============================================================
    
    function task_table = local_build_task_table(grid_table, Tw_grid_s)
    
        nCfg = height(grid_table);
        nTw = numel(Tw_grid_s);
    
        cfg_id = zeros(nCfg*nTw, 1);
        Tw_s = zeros(nCfg*nTw, 1);
    
        ptr = 0;
        for iCfg = 1:nCfg
            for iTw = 1:nTw
                ptr = ptr + 1;
                cfg_id(ptr) = iCfg;
                Tw_s(ptr) = Tw_grid_s(iTw);
            end
        end
    
        task_table = table(cfg_id, Tw_s, 'VariableNames', {'cfg_id','Tw_s'});
    end
    
    
    function case_item = local_build_case_item_from_row(Trow, nominal_bank, cfg, prefix)
    
        entry_id = local_get_table_scalar(Trow, 'entry_id', NaN);
        heading_deg = local_get_table_scalar(Trow, 'heading_deg', NaN);
        family_name = string(local_get_table_scalar(Trow, 'family_name', "unknown"));
    
        base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id);
        assert(~isempty(base_item), 'Failed to find nominal case for entry_id=%g.', entry_id);
    
        base_case = base_item.case;
        nominal_heading_deg = local_extract_numeric(base_case, 'heading_deg', NaN);
    
        case_new = base_case;
        case_new.heading_deg = heading_deg;
        case_new.heading_offset_deg = local_wrapTo180(heading_deg - nominal_heading_deg);
        case_new.nominal_heading_deg = nominal_heading_deg;
        case_new.entry_id = entry_id;
        case_new.entry_point_id = entry_id;
        case_new.family = 'stage08_boundary';
        case_new.subfamily = char(family_name);
        case_new.sample_type = char(family_name);
        case_new.family_name = char(family_name);
        case_new.source_case_id = char(string(base_case.case_id));
        case_new.case_id = sprintf('%s_E%02d_%s_H%03d', prefix, round(entry_id), char(family_name), round(heading_deg));
    
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
    
    
    % ============================================================
    % main task evaluation
    % ============================================================
    
    function [task_row_struct, case_scan_table, dominant_struct] = local_run_boundary_task(task_row, config_bank, hardcase_table, hardcase_bank, hardcase_items, cfg, q)

        cfg_id = task_row.cfg_id;
        Tw_s = task_row.Tw_s;

        cfg_item = config_bank(cfg_id);
        grid_row = cfg_item.grid_row;
        ref_walker = cfg_item.ref_walker;
        gamma_req = cfg_item.gamma_req;
    
        cfg_eval = cfg;
        cfg_eval.stage04.Tw_s = Tw_s;
    
        nHard = height(hardcase_table);
    
        raw_case_rows = cell(nHard, 1);
        DG_vals = nan(nHard, 1);
        fam_vals = strings(nHard, 1);
    
        for iHard = 1:nHard
            eval_out = evaluate_critical_case_geometry_stage07( ...
                hardcase_items{iHard}, ref_walker, gamma_req, cfg_eval);

            diag_row = eval_out.diag_row;
            hard_item = hardcase_bank(iHard);

            raw_case_rows{iHard} = local_build_raw_case_row( ...
                grid_row, hard_item, Tw_s, diag_row);

            DG_vals(iHard) = local_get_diag_scalar(diag_row, 'D_G_min', NaN);
            fam_vals(iHard) = hard_item.family_name;
        end
    
        case_scan_table = struct2table(vertcat(raw_case_rows{:}));
    
        [is_feasible_boundary, tail_hard_min, tail_C2_min] = ...
            local_eval_boundary_feasibility(DG_vals, fam_vals, cfg);
    
        [DG_sorted, idx_sorted] = sort(DG_vals, 'ascend', 'MissingPlacement', 'last');
        iDom = idx_sorted(1);
    
        dominant_struct = struct();
        dominant_struct.cfg_id = cfg_id;
        dominant_struct.Tw_s = Tw_s;
        dominant_struct.dominant_hard_id = hardcase_bank(iDom).hard_id;
        dominant_struct.dominant_family = hardcase_bank(iDom).family_name;
        dominant_struct.dominant_entry_id = hardcase_bank(iDom).entry_id;
        dominant_struct.dominant_heading_deg = hardcase_bank(iDom).heading_deg;
        dominant_struct.dominant_D_G_min = DG_sorted(1);
    
        task_row_struct = struct();
        task_row_struct.cfg_id = cfg_id;
        task_row_struct.h_km = local_get_table_scalar(grid_row, 'h_km', NaN);
        task_row_struct.i_deg = local_get_table_scalar(grid_row, 'i_deg', NaN);
        task_row_struct.P = local_get_table_scalar(grid_row, 'P', NaN);
        task_row_struct.T = local_get_table_scalar(grid_row, 'T', NaN);
        task_row_struct.F = local_get_table_scalar(grid_row, 'F', 1);
        task_row_struct.Ns = local_get_table_scalar(grid_row, 'Ns', NaN);
        task_row_struct.Tw_s = Tw_s;
    
        task_row_struct.n_hardcase = nHard;
        task_row_struct.D_G_min = min(DG_vals, [], 'omitnan');
        task_row_struct.D_G_median = median(DG_vals, 'omitnan');
        task_row_struct.D_G_mean = mean(DG_vals, 'omitnan');
        task_row_struct.tail_hard_min = tail_hard_min;
        task_row_struct.tail_C2_min = tail_C2_min;
        task_row_struct.is_feasible_boundary = is_feasible_boundary;
    
        if ~isempty(q)
            send(q, local_make_progress_msg_from_taskrow(task_row_struct));
        end
    end
    
    
    function ref_walker = local_make_ref_from_grid_row(grid_row, cfg)
    
        ref_walker = struct();
        ref_walker.ref_id = local_get_table_scalar(grid_row, 'cfg_id', NaN);
        ref_walker.source_stage = 'stage08c_weakside';
        ref_walker.selection_rule = 'boundary_weakside_grid';
    
        ref_walker.h_km = local_get_table_scalar(grid_row, 'h_km', NaN);
        ref_walker.i_deg = local_get_table_scalar(grid_row, 'i_deg', NaN);
        ref_walker.P = local_get_table_scalar(grid_row, 'P', NaN);
        ref_walker.T = local_get_table_scalar(grid_row, 'T', NaN);
        ref_walker.F = local_get_table_scalar(grid_row, 'F', 1);
        ref_walker.Ns = local_get_table_scalar(grid_row, 'Ns', ref_walker.P * ref_walker.T);
    
        if isfield(cfg, 'stage05') && isfield(cfg.stage05, 'require_D_G_min')
            ref_walker.gamma_req = cfg.stage05.require_D_G_min;
        else
            ref_walker.gamma_req = 1.0;
        end
    end
    
    
    function row = local_build_raw_case_row(grid_row, hard_item, Tw_s, diag_row)
    
        row = struct();
        row.cfg_id = local_get_table_scalar(grid_row, 'cfg_id', NaN);
        row.h_km = local_get_table_scalar(grid_row, 'h_km', NaN);
        row.i_deg = local_get_table_scalar(grid_row, 'i_deg', NaN);
        row.P = local_get_table_scalar(grid_row, 'P', NaN);
        row.T = local_get_table_scalar(grid_row, 'T', NaN);
        row.F = local_get_table_scalar(grid_row, 'F', 1);
        row.Ns = local_get_table_scalar(grid_row, 'Ns', NaN);
        row.Tw_s = Tw_s;
    
        row.hard_id = hard_item.hard_id;
        row.family_name = hard_item.family_name;
        row.entry_id = hard_item.entry_id;
        row.heading_deg = hard_item.heading_deg;
    
        row.lambda_worst = local_get_diag_scalar(diag_row, 'lambda_worst', NaN);
        row.D_G_min = local_get_diag_scalar(diag_row, 'D_G_min', NaN);
        row.t0_worst = local_get_diag_scalar(diag_row, 't0_worst', NaN);
        row.coverage_ratio_2sat = local_get_diag_scalar(diag_row, 'coverage_ratio_2sat', NaN);
        row.mean_los_intersection_angle_deg = local_get_diag_scalar(diag_row, 'mean_los_intersection_angle_deg', NaN);
    end
    
    
    function [flag, tail_hard_min, tail_C2_min] = local_eval_boundary_feasibility(DG_vals, fam_vals, cfg)
    
        req = cfg.stage08c.require_DG_min;
        kH = min(cfg.stage08c.tail_hard_k, numel(DG_vals));
    
        DG_sorted = sort(DG_vals, 'ascend', 'MissingPlacement', 'last');
        tail_hard_min = min(DG_sorted(1:kH), [], 'omitnan');
    
        idxC2 = fam_vals == "C2";
        if any(idxC2)
            DG_C2 = sort(DG_vals(idxC2), 'ascend', 'MissingPlacement', 'last');
            kC2 = min(cfg.stage08c.tail_C2_k, numel(DG_C2));
            tail_C2_min = min(DG_C2(1:kC2), [], 'omitnan');
        else
            tail_C2_min = NaN;
        end
    
        flag = isfinite(tail_hard_min) && isfinite(tail_C2_min) && ...
               (tail_hard_min >= req) && (tail_C2_min >= req);
    end


    function config_bank = local_build_stage08c_config_bank(grid_table, cfg)

        nCfg = height(grid_table);
        config_bank = repmat(struct( ...
            'grid_row', table(), ...
            'ref_walker', struct(), ...
            'gamma_req', NaN), nCfg, 1);

        for iCfg = 1:nCfg
            grid_row = grid_table(iCfg, :);
            ref_walker = local_make_ref_from_grid_row(grid_row, cfg);
            config_bank(iCfg).grid_row = grid_row;
            config_bank(iCfg).ref_walker = ref_walker;
            config_bank(iCfg).gamma_req = local_resolve_gamma_req(ref_walker, cfg);
        end
    end


    function hardcase_bank = local_build_stage08c_hardcase_bank(hardcase_table)

        nHard = height(hardcase_table);
        hardcase_bank = repmat(struct( ...
            'hard_id', NaN, ...
            'family_name', "", ...
            'entry_id', NaN, ...
            'heading_deg', NaN), nHard, 1);

        for iHard = 1:nHard
            hard_row = hardcase_table(iHard, :);
            hardcase_bank(iHard).hard_id = local_get_table_scalar(hard_row, 'hard_id', NaN);
            hardcase_bank(iHard).family_name = string(local_get_table_scalar(hard_row, 'family_name', ""));
            hardcase_bank(iHard).entry_id = local_get_table_scalar(hard_row, 'entry_id', NaN);
            hardcase_bank(iHard).heading_deg = local_get_table_scalar(hard_row, 'heading_deg', NaN);
        end
    end
    
    
    function msg = local_make_progress_msg_from_taskrow(task_row_struct)
        msg = struct();
        msg.cfg_id = task_row_struct.cfg_id;
        msg.Tw_s = task_row_struct.Tw_s;
        msg.is_feasible_boundary = task_row_struct.is_feasible_boundary;
        msg.tail_hard_min = task_row_struct.tail_hard_min;
        msg.tail_C2_min = task_row_struct.tail_C2_min;
        msg.D_G_median = task_row_struct.D_G_median;
    end
    
    
    % ============================================================
    % summaries
    % ============================================================
    
    function T = local_build_Tw_summary_table_stage08c(raw_task_table)
    
        Tw_vals = unique(raw_task_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_task_table(raw_task_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible_boundary == true, :);
            num_feasible = height(feasible_sub);
    
            r = struct();
            r.Tw_s = Tw;
            r.num_config = height(sub);
            r.num_feasible = num_feasible;
            r.feasible_ratio = num_feasible / max(1, height(sub));
    
            if num_feasible >= 1
                r.N_min = min(feasible_sub.Ns, [], 'omitnan');
                best_sub = feasible_sub(feasible_sub.Ns == r.N_min, :);
                [~, idx_best] = max(best_sub.D_G_median);
                best_row = best_sub(idx_best, :);
    
                r.best_cfg_id = best_row.cfg_id;
                r.best_Ns = best_row.Ns;
                r.best_DG_median = best_row.D_G_median;
                r.best_tail_hard_min = best_row.tail_hard_min;
                r.best_tail_C2_min = best_row.tail_C2_min;
            else
                r.N_min = NaN;
                r.best_cfg_id = NaN;
                r.best_Ns = NaN;
                r.best_DG_median = NaN;
                r.best_tail_hard_min = NaN;
                r.best_tail_C2_min = NaN;
            end
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    
        % flip_count attached later
        T.flip_count = zeros(height(T), 1);
    end
    
    
    function T = local_build_best_config_table_stage08c(raw_task_table)
    
        Tw_vals = unique(raw_task_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_task_table(raw_task_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible_boundary == true, :);
            if isempty(feasible_sub)
                feasible_sub = sortrows(sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                best_flag = false;
            else
                feasible_sub = sortrows(feasible_sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                best_flag = true;
            end
    
            r = table2struct(best_row);
            r.best_is_feasible = best_flag;
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    function flip_table = local_build_flip_table_stage08c(raw_task_table)
    
        cfg_ids = unique(raw_task_table.cfg_id);
        rows = {};
    
        ptr = 0;
        for i = 1:numel(cfg_ids)
            sub = raw_task_table(raw_task_table.cfg_id == cfg_ids(i), :);
            sub = sortrows(sub, 'Tw_s', 'ascend');
    
            feas = logical(sub.is_feasible_boundary);
            Tws = sub.Tw_s;
    
            if all(feas)
                flip_type = "always_pass";
                Tw_fail_max = NaN;
                Tw_pass_min = min(Tws);
            elseif ~any(feas)
                flip_type = "always_fail";
                Tw_fail_max = max(Tws);
                Tw_pass_min = NaN;
            else
                idx_pass = find(feas, 1, 'first');
                idx_fail = find(~feas, 1, 'last');
                if idx_pass > 1 && all(~feas(1:idx_pass-1)) && all(feas(idx_pass:end))
                    flip_type = "fail_to_pass";
                    Tw_fail_max = Tws(idx_pass-1);
                    Tw_pass_min = Tws(idx_pass);
                else
                    flip_type = "mixed";
                    Tw_fail_max = max(Tws(~feas));
                    Tw_pass_min = min(Tws(feas));
                end
            end
    
            ptr = ptr + 1;
            r = struct();
            r.cfg_id = cfg_ids(i);
            r.h_km = sub.h_km(1);
            r.i_deg = sub.i_deg(1);
            r.P = sub.P(1);
            r.T = sub.T(1);
            r.Ns = sub.Ns(1);
            r.flip_type = flip_type;
            r.Tw_fail_max = Tw_fail_max;
            r.Tw_pass_min = Tw_pass_min;
            rows{ptr,1} = r; %#ok<AGROW>
        end
    
        flip_table = struct2table(vertcat(rows{:}));
        flip_table = sortrows(flip_table, {'flip_type','Ns','i_deg'}, {'ascend','ascend','ascend'});
    end
    
    
    % ============================================================
    % plotting
    % ============================================================
    
    function fig = local_plot_scalar_vs_Tw(T, varname, ylabel_str, ttl)
    
        fig = figure('Color', 'w', 'Position', [120 120 900 520]);
        hold on; grid on; box on;
    
        plot(T.Tw_s, T.(varname), '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
        xlabel('Tw (s)');
        ylabel(ylabel_str);
        title(ttl, 'Interpreter', 'none');
    end
    
    
    function fig = local_plot_feasibility_heatmap(raw_task_table)
    
        fig = figure('Color', 'w', 'Position', [120 120 1000 650]);
    
        cfg_keys = unique(raw_task_table(:, {'cfg_id','Ns','i_deg'}), 'rows', 'stable');
        cfg_keys = sortrows(cfg_keys, {'Ns','i_deg','cfg_id'}, {'ascend','ascend','ascend'});
        Tw_vals = sort(unique(raw_task_table.Tw_s), 'ascend');
    
        M = nan(height(cfg_keys), numel(Tw_vals));
        for iCfg = 1:height(cfg_keys)
            cid = cfg_keys.cfg_id(iCfg);
            for iTw = 1:numel(Tw_vals)
                idx = raw_task_table.cfg_id == cid & raw_task_table.Tw_s == Tw_vals(iTw);
                vals = raw_task_table.is_feasible_boundary(idx);
                if ~isempty(vals)
                    M(iCfg, iTw) = double(vals(1));
                end
            end
        end
    
        imagesc(Tw_vals, 1:height(cfg_keys), M);
        set(gca, 'YDir', 'normal');
        xlabel('Tw (s)');
        ylabel('config index');
        title('Stage08.4c feasibility heatmap', 'Interpreter', 'none');
        colorbar;
    end
    
    
    % ============================================================
    % generic table / struct helpers
    % ============================================================
    
    function family = local_get_family_col(T)
    
        if any(strcmp(T.Properties.VariableNames, 'family_name'))
            family = string(T.family_name);
            return;
        end
        if any(strcmp(T.Properties.VariableNames, 'sample_type'))
            family = string(T.sample_type);
            return;
        end
        if any(strcmp(T.Properties.VariableNames, 'group_value'))
            family = string(T.group_value);
            return;
        end
    
        family = repmat("unknown", height(T), 1);
    end
    
    
    function x = local_get_numeric_col(T, candidates, default_val)
    
        x = repmat(default_val, height(T), 1);
    
        for i = 1:numel(candidates)
            c = candidates{i};
            if any(strcmp(T.Properties.VariableNames, c))
                v = T.(c);
                if isnumeric(v)
                    x = double(v);
                else
                    try
                        x = double(v);
                    catch
                        x = repmat(default_val, height(T), 1);
                    end
                end
                return;
            end
        end
    end
    
    
    function value = local_get_table_scalar(Trow, field_name, default_value)
    
        value = default_value;
        if istable(Trow) && height(Trow) >= 1 && any(strcmp(Trow.Properties.VariableNames, field_name))
            tmp = Trow.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function value = local_get_diag_scalar(diag_row, field_name, default_value)
    
        value = default_value;
    
        if isstruct(diag_row) && isfield(diag_row, field_name)
            tmp = diag_row.(field_name);
            if ~isempty(tmp)
                value = tmp;
            end
            return;
        end
    
        if istable(diag_row) && height(diag_row) >= 1 && any(strcmp(diag_row.Properties.VariableNames, field_name))
            tmp = diag_row.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function gamma_req = local_resolve_gamma_req(ref_walker, cfg)
    
        gamma_req = NaN;
        if isstruct(ref_walker) && isfield(ref_walker, 'gamma_req') && ~isempty(ref_walker.gamma_req)
            gamma_req = ref_walker.gamma_req;
        end
        if ~isfinite(gamma_req) && isfield(cfg, 'stage05') && isfield(cfg.stage05, 'require_D_G_min')
            gamma_req = cfg.stage05.require_D_G_min;
        end
        if ~isfinite(gamma_req)
            gamma_req = 1.0;
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
    
    
    function x = local_wrapTo180(x)
        x = mod(x + 180, 360) - 180;
    end
    
    
    function c = local_make_missing_column(n)
        c = repmat(missing, n, 1);
    end

    function cache_file = local_find_latest_stage07_cache(cache_dir, prefix, cfg)

        % Priority 1: use cfg.stage07.run_tag if available
        if isstruct(cfg) && isfield(cfg, 'stage07') && isstruct(cfg.stage07) && ...
                isfield(cfg.stage07, 'run_tag') && ~isempty(cfg.stage07.run_tag)
    
            pattern = sprintf('%s_%s_*.mat', prefix, char(cfg.stage07.run_tag));
            d = dir(fullfile(cache_dir, pattern));
            if ~isempty(d)
                [~, idx] = max([d.datenum]);
                cache_file = fullfile(d(idx).folder, d(idx).name);
                return;
            end
        end
    
        % Priority 2: fallback to any matching prefix
        pattern = sprintf('%s_*.mat', prefix);
        d = dir(fullfile(cache_dir, pattern));
        assert(~isempty(d), 'No cache matched prefix: %s', prefix);
    
        [~, idx] = max([d.datenum]);
        cache_file = fullfile(d(idx).folder, d(idx).name);
    end

    function T = local_attach_flip_count_stage08c(T, flip_table)

        if isempty(T) || isempty(flip_table)
            return;
        end
    
        T.flip_count = zeros(height(T), 1);
    
        if ~any(strcmp(flip_table.Properties.VariableNames, 'flip_type')) || ...
           ~any(strcmp(flip_table.Properties.VariableNames, 'Tw_pass_min'))
            return;
        end
    
        idx_flip = string(flip_table.flip_type) == "fail_to_pass" & isfinite(flip_table.Tw_pass_min);
        F = flip_table(idx_flip, :);
    
        if isempty(F)
            return;
        end
    
        for i = 1:height(T)
            T.flip_count(i) = sum(F.Tw_pass_min == T.Tw_s(i));
        end
    end
