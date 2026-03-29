function out = stage14_scan_openD_raan_grid(cfg, overrides)
%STAGE14_SCAN_OPEND_RAAN_GRID
% Stage14.1 mainline:
%   Raw DG-only scan over (i, P, T, RAAN) with fixed F_ref.
%
% Current scope:
%   - serial/parallel execution
%   - no plots
%   - cache + csv export
%   - strict Stage05-compatible DG-only pass criterion

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    cfg = stage14_default_config(cfg, overrides);
    cfg.project_stage = 'stage14_scan_openD_raan_grid';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    log_file = fullfile(cfg.paths.logs, sprintf('stage14_scan_openD_raan_grid_%s.log', timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage14.1 mainline started.');

    [S4, stage04_file, gamma_req] = local_load_stage04_gamma(cfg, log_fid); %#ok<ASGLU>
    cfg.stage04.gamma_req = gamma_req;

    [S2, stage02_file, trajs_nominal] = local_load_stage02_nominal(cfg, log_fid); %#ok<ASGLU>
    if isfinite(cfg.stage14.case_limit) && cfg.stage14.case_limit < numel(trajs_nominal)
        trajs_nominal = trajs_nominal(1:cfg.stage14.case_limit);
        log_msg(log_fid, 'INFO', 'Applied case_limit: %d', numel(trajs_nominal));
    end

    hard_order = local_build_hard_order(S4, trajs_nominal, cfg);
    eval_context = local_prepare_eval_context(trajs_nominal, cfg);

    grid = build_stage14_search_grid(cfg);
    grid.gamma_req(:) = gamma_req;
    nGrid = height(grid);
    grid_rows = table2struct(grid);

    log_msg(log_fid, 'INFO', 'Stage14 grid size: %d', nGrid);
    log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));

    parallel_state = local_prepare_parallel_pool(cfg, log_fid);
    log_msg(log_fid, 'INFO', 'Stage14 execution mode: %s', char(parallel_state.mode));
    if parallel_state.enabled
        log_msg(log_fid, 'INFO', 'Parallel pool profile: %s', char(parallel_state.profile));
        log_msg(log_fid, 'INFO', 'Parallel pool workers: %d', parallel_state.num_workers);
    end

    t_all = tic;
    if parallel_state.enabled
        result_rows = local_evaluate_grid_parallel(grid_rows, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
    else
        result_rows = local_evaluate_grid_serial(grid_rows, trajs_nominal, gamma_req, cfg, hard_order, eval_context, log_fid);
    end
    grid = local_apply_result_rows_to_grid(grid, result_rows);
    dt_all = toc(t_all);

    summary = local_build_summary(grid, cfg, stage02_file, stage04_file, gamma_req, dt_all, parallel_state);

    files = struct();
    files.log_file = log_file;
    files.cache_file = '';
    files.table_file = '';

    out = struct();
    out.cfg = cfg;
    out.grid = grid;
    out.summary = summary;
    out.files = files;

    if cfg.stage14.save_table
        files.table_file = fullfile(cfg.paths.tables, sprintf('stage14_grid_%s.csv', timestamp));
        writetable(grid, files.table_file);
        log_msg(log_fid, 'INFO', 'Saved grid csv: %s', files.table_file);
    end

    if cfg.stage14.save_cache
        files.cache_file = fullfile(cfg.paths.cache, sprintf('stage14_scan_openD_raan_grid_%s.mat', timestamp));
        out.files = files;
        save(files.cache_file, 'out', '-v7.3');
        log_msg(log_fid, 'INFO', 'Saved cache: %s', files.cache_file);
    else
        out.files = files;
    end

    log_msg(log_fid, 'INFO', 'Stage14.1 mainline finished in %.3f s.', dt_all);
end

function [S4, stage04_file, gamma_req] = local_load_stage04_gamma(cfg, log_fid)
    listing = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
    assert(~isempty(listing), 'No Stage04 cache found. Please run stage04_window_worstcase first.');

    [~, idx] = max([listing.datenum]);
    stage04_file = fullfile(listing(idx).folder, listing(idx).name);
    S4 = load(stage04_file);

    assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
    assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
        'Stage04 cache missing summary.gamma_meta');

    gamma_req = S4.out.summary.gamma_meta.gamma_req;
    log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
    log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
end

function [S2, stage02_file, trajs_nominal] = local_load_stage02_nominal(cfg, log_fid)
    listing = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(listing), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

    [~, idx] = max([listing.datenum]);
    stage02_file = fullfile(listing(idx).folder, listing(idx).name);
    S2 = load(stage02_file);

    assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
        'Invalid Stage02 cache: missing out.trajbank.nominal');

    trajs_nominal = S2.out.trajbank.nominal;
    log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
    log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));
end

function hard_order = local_build_hard_order(S4, trajs_nominal, cfg)
    hard_order = (1:numel(trajs_nominal)).';

    if ~cfg.stage14.hard_case_first
        return;
    end

    try
        if isfield(S4.out.summary, 'margin') && isfield(S4.out.summary.margin, 'case_table')
            tab4 = S4.out.summary.margin.case_table;
        elseif isfield(S4.out.summary, 'spectrum') && isfield(S4.out.summary.spectrum, 'case_table')
            tab4 = S4.out.summary.spectrum.case_table;
        else
            tab4 = table();
        end

        if isempty(tab4)
            return;
        end

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
    catch
        % fallback silently
    end
end

function eval_context = local_prepare_eval_context(trajs_in, cfg)
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;

    eval_context = struct();
    eval_context.t_s_common = (0:dt:t_max).';
end

function result_rows = local_evaluate_grid_serial(grid_rows, trajs_nominal, gamma_req, cfg, hard_order, eval_context, log_fid)
    nGrid = numel(grid_rows);
    result_rows = cell(nGrid, 1);

    for ig = 1:nGrid
        row = grid_rows(ig);
        result = evaluate_single_layer_walker_stage14(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
        result_rows{ig} = local_pack_grid_result(result);

        if mod(ig, cfg.stage14.progress_every) == 0 || ig == nGrid
            log_msg(log_fid, 'INFO', ...
                '[%d/%d] i=%.1f, P=%d, T=%d, RAAN=%.1f, Ns=%d, D_G_min=%.6f, pass_ratio=%.6f, feasible=%d, n_eval=%d, early=%d', ...
                ig, nGrid, row.i_deg, row.P, row.T, row.RAAN_deg, row.Ns, ...
                result.D_G_min, result.pass_ratio, logical(result.feasible_flag), ...
                result.n_case_evaluated, logical(result.failed_early));
        end
    end
end

function result_rows = local_evaluate_grid_parallel(grid_rows, trajs_nominal, gamma_req, cfg, hard_order, eval_context)
    nGrid = numel(grid_rows);
    result_rows = cell(nGrid, 1);

    parfor ig = 1:nGrid
        row = grid_rows(ig);
        result = evaluate_single_layer_walker_stage14(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
        result_rows{ig} = local_pack_grid_result(result);
    end
end

function packed = local_pack_grid_result(result)
    packed = struct();
    packed.is_evaluated = true;
    packed.lambda_worst_min = result.lambda_worst_min;
    packed.lambda_worst_mean = result.lambda_worst_mean;
    packed.D_G_min = result.D_G_min;
    packed.D_G_mean = result.D_G_mean;
    packed.pass_ratio = result.pass_ratio;
    packed.feasible_flag = logical(result.feasible_flag);
    packed.rank_score = result.rank_score;
    packed.n_case_evaluated = result.n_case_evaluated;
    packed.failed_early = logical(result.failed_early);
end

function grid = local_apply_result_rows_to_grid(grid, result_rows)
    nGrid = numel(result_rows);
    for ig = 1:nGrid
        result = result_rows{ig};
        grid.is_evaluated(ig) = result.is_evaluated;
        grid.lambda_worst_min(ig) = result.lambda_worst_min;
        grid.lambda_worst_mean(ig) = result.lambda_worst_mean;
        grid.D_G_min(ig) = result.D_G_min;
        grid.D_G_mean(ig) = result.D_G_mean;
        grid.pass_ratio(ig) = result.pass_ratio;
        grid.feasible_flag(ig) = result.feasible_flag;
        grid.rank_score(ig) = result.rank_score;
        grid.n_case_evaluated(ig) = result.n_case_evaluated;
        grid.failed_early(ig) = result.failed_early;
    end
end

function summary = local_build_summary(grid, cfg, stage02_file, stage04_file, gamma_req, dt_all, parallel_state)
    summary = struct();
    summary.stage = 'stage14.1_mainline';
    summary.mode = string(cfg.stage14.mode);
    summary.stage02_file = stage02_file;
    summary.stage04_file = stage04_file;
    summary.gamma_req = gamma_req;
    summary.grid_size = height(grid);
    summary.elapsed_s = dt_all;
    summary.parallel_enabled = parallel_state.enabled;
    summary.parallel_mode = parallel_state.mode;
    summary.parallel_profile = parallel_state.profile;
    summary.parallel_workers = parallel_state.num_workers;

    summary.n_feasible = sum(grid.feasible_flag, 'omitnan');
    summary.best_pass_ratio = max(grid.pass_ratio, [], 'omitnan');
    summary.best_D_G_min = max(grid.D_G_min, [], 'omitnan');

    if any(grid.feasible_flag)
        feasible_grid = grid(grid.feasible_flag, :);
        [~, idx] = min(feasible_grid.Ns);
        summary.min_feasible_Ns = feasible_grid.Ns(idx);
    else
        summary.min_feasible_Ns = NaN;
    end
end

function parallel_state = local_prepare_parallel_pool(cfg, log_fid)
    parallel_state = struct();
    parallel_state.enabled = false;
    parallel_state.mode = "serial";
    parallel_state.profile = "";
    parallel_state.num_workers = 0;

    if ~isfield(cfg, 'stage14') || ~isstruct(cfg.stage14) || ~logical(cfg.stage14.use_parallel)
        return;
    end

    profile_name = 'local';
    if isfield(cfg.stage14, 'parallel') && isstruct(cfg.stage14.parallel) && ...
            isfield(cfg.stage14.parallel, 'prefer_threads') && cfg.stage14.parallel.prefer_threads
        profile_name = 'threads';
    end

    num_workers = [];
    if isfield(cfg.stage14, 'parallel') && isstruct(cfg.stage14.parallel) && ...
            isfield(cfg.stage14.parallel, 'max_workers') && ~isempty(cfg.stage14.parallel.max_workers)
        num_workers = cfg.stage14.parallel.max_workers;
    end

    try
        pool = ensure_parallel_pool(profile_name, num_workers);
        if isempty(pool)
            log_msg(log_fid, 'WARN', 'Parallel mode requested but no pool is available. Falling back to serial.');
            return;
        end

        parallel_state.enabled = true;
        parallel_state.mode = "parallel";
        parallel_state.profile = string(profile_name);
        parallel_state.num_workers = pool.NumWorkers;
    catch ME
        log_msg(log_fid, 'WARN', 'Parallel mode requested but pool setup failed: %s', ME.message);
        log_msg(log_fid, 'WARN', 'Falling back to serial execution for Stage14.1.');
    end
end
