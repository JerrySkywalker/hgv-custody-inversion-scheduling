function out = stage09_build_feasible_domain(cfg, opts)
%STAGE09_BUILD_FEASIBLE_DOMAIN
% Stage09.4:
%   Scan the Walker parameter grid and build the feasible domain under
%   robust D-series constraints.
%
% Main outputs:
%   out.full_theta_table
%   out.feasible_theta_table
%   out.infeasible_theta_table
%   out.fail_partition_table
%   out.summary_table
%
% This stage is the first true "inverse-design domain" stage:
%   Theta  -->  {DG_rob, DA_rob, DT_rob}  -->  feasible domain

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg = local_apply_stage09_opts(cfg, opts);
    cfg.project_stage = 'stage09_build_feasible_domain';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_build_feasible_domain_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.4 started.');

    % ------------------------------------------------------------
    % Build casebank (validation/demo route for now)
    % ------------------------------------------------------------
    trajs_in = build_stage09_casebank(cfg);

    if isfinite(cfg.stage09.scan_case_limit)
        nKeep = min(numel(trajs_in), cfg.stage09.scan_case_limit);
        trajs_in = trajs_in(1:nKeep);
    end

    % ------------------------------------------------------------
    % Build search grid
    % ------------------------------------------------------------
    Tsearch = local_build_search_domain_table_stage09(cfg);

    if isfinite(cfg.stage09.scan_theta_limit)
        Tsearch = Tsearch(1:min(height(Tsearch), cfg.stage09.scan_theta_limit), :);
    end
    row_bank = table2struct(Tsearch);

    nTheta = height(Tsearch);
    if nTheta < 1
        error('Stage09 search domain is empty.');
    end

    gamma_info = resolve_stage09_gamma_req(cfg);
    gamma_eff_scalar = gamma_info.gamma_req;
    cfg.stage04.gamma_req = gamma_eff_scalar;
    cfg.stage09.gamma_req = gamma_eff_scalar;
    cfg.stage09.gamma_eff_scalar = gamma_eff_scalar;

    log_msg(log_fid, 'INFO', 'gamma_source     = %s', char(gamma_info.source_label));
    log_msg(log_fid, 'INFO', 'gamma_req        = %.6e', gamma_eff_scalar);
    log_msg(log_fid, 'INFO', 'gamma_cache_file = %s', char(gamma_info.cache_file));
    eval_ctx = build_stage09_eval_context(trajs_in, cfg, gamma_eff_scalar);

    % Use the first evaluated design as the struct template, so that
    % later indexed assignment is field-compatible.
    first_row = row_bank(1);
    first_result = evaluate_single_layer_walker_stage09(first_row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);

    result_bank = repmat(first_result, nTheta, 1);
    result_bank(1) = first_result;

    t_scan = tic;
    use_parallel = local_prepare_stage09_parallel(cfg, log_fid);
    disable_progress = isfield(cfg.stage09, 'disable_progress') && cfg.stage09.disable_progress;
    if use_parallel
        parfor it = 2:nTheta
            row = row_bank(it);
            result_bank(it) = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);
        end
    else
        for it = 2:nTheta
            row = row_bank(it);
            result_bank(it) = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);

            if ~disable_progress && (mod(it, cfg.stage09.scan_log_every) == 0 || it == 2 || it == nTheta)
                log_msg(log_fid, 'INFO', ...
                    'Scanned %d / %d designs (%.1f%%). Current: h=%.0f km, i=%.0f deg, P=%d, T=%d, feasible=%d', ...
                    it, nTheta, 100*it/nTheta, ...
                    row.h_km, row.i_deg, row.P, row.T, result_bank(it).feasible_flag);
            end
        end
    end

    % Handle the one-design corner case explicitly
    if nTheta == 1
        log_msg(log_fid, 'INFO', ...
            'Scanned %d / %d designs (%.1f%%). Current: h=%.0f km, i=%.0f deg, P=%d, T=%d, feasible=%d', ...
            1, nTheta, 100, ...
            first_row.h_km, first_row.i_deg, first_row.P, first_row.T, first_result.feasible_flag);
    end
    elapsed_s = toc(t_scan);

    % ------------------------------------------------------------
    % Summarize
    % ------------------------------------------------------------
    S = summarize_stage09_grid(result_bank, cfg);

    if cfg.stage09.write_csv
        full_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_full_theta_table_%s_%s.csv', run_tag, timestamp));
        feasible_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_feasible_theta_table_%s_%s.csv', run_tag, timestamp));
        infeasible_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_infeasible_theta_table_%s_%s.csv', run_tag, timestamp));
        fail_partition_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_fail_partition_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_feasible_domain_summary_%s_%s.csv', run_tag, timestamp));

        writetable(S.full_theta_table, full_csv);
        writetable(S.feasible_theta_table, feasible_csv);
        writetable(S.infeasible_theta_table, infeasible_csv);
        writetable(S.fail_partition_table, fail_partition_csv);
        writetable(S.summary_table, summary_csv);
    else
        full_csv = "";
        feasible_csv = "";
        infeasible_csv = "";
        fail_partition_csv = "";
        summary_csv = "";
    end

    % ------------------------------------------------------------
    % Package outputs
    % ------------------------------------------------------------
    out = struct();
    out.cfg = cfg;
    out.gamma_info = gamma_info;
    out.full_theta_table = S.full_theta_table;
    if isfield(S, 'stage05_compat_theta_table')
        out.stage05_compat_theta_table = S.stage05_compat_theta_table;
    end
    out.feasible_theta_table = S.feasible_theta_table;
    out.infeasible_theta_table = S.infeasible_theta_table;
    out.fail_partition_table = S.fail_partition_table;
    out.summary_table = S.summary_table;
    out.result_bank = result_bank;

    out.files = struct();
    out.files.log_file = log_file;
    out.files.full_csv = full_csv;
    out.files.feasible_csv = feasible_csv;
    out.files.infeasible_csv = infeasible_csv;
    out.files.fail_partition_csv = fail_partition_csv;
    out.files.summary_csv = summary_csv;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_build_feasible_domain_%s_%s.mat', run_tag, timestamp));
    if ~isfield(cfg.stage09, 'save_cache_file') || cfg.stage09.save_cache_file
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    else
        out.files.cache_file = "";
    end

    log_msg(log_fid, 'INFO', 'Scan elapsed time = %.3f s', elapsed_s);
    log_msg(log_fid, 'INFO', 'gamma source cache = %s', char(gamma_info.cache_file));
    log_msg(log_fid, 'INFO', 'Total theta      = %d', height(S.full_theta_table));
    log_msg(log_fid, 'INFO', 'Feasible theta   = %d', height(S.feasible_theta_table));
    log_msg(log_fid, 'INFO', 'Infeasible theta = %d', height(S.infeasible_theta_table));
    if strlength(string(out.files.cache_file)) > 0
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
    else
        log_msg(log_fid, 'INFO', 'Cache save skipped.');
    end
    log_msg(log_fid, 'INFO', 'Stage09.4 finished.');

    fprintf('\n');
    fprintf('========== Stage09.4 Feasible-Domain Summary ==========\n');
    disp(S.summary_table);
    disp(S.fail_partition_table);
    fprintf('gamma_req      : %.6e\n', gamma_eff_scalar);
    fprintf('gamma cache    : %s\n', char(gamma_info.cache_file));
    if strlength(string(out.files.cache_file)) > 0
        fprintf('Cache          : %s\n', cache_file);
    end
    if cfg.stage09.write_csv
        fprintf('Full table CSV : %s\n', full_csv);
        fprintf('Feasible CSV   : %s\n', feasible_csv);
        fprintf('Infeasible CSV : %s\n', infeasible_csv);
        fprintf('Fail-tag CSV   : %s\n', fail_partition_csv);
        fprintf('Summary CSV    : %s\n', summary_csv);
    end
    fprintf('=======================================================\n');
end


function cfg = local_apply_stage09_opts(cfg, opts)

    if isfield(opts, 'mode') && ~isempty(opts.mode)
        cfg.stage09.use_parallel = strcmpi(string(opts.mode), "parallel");
    end

    if isfield(opts, 'parallel_config') && isstruct(opts.parallel_config)
        if isfield(opts.parallel_config, 'profile_name') && ~isempty(opts.parallel_config.profile_name)
            cfg.stage09.parallel_pool_profile = char(string(opts.parallel_config.profile_name));
        end
        if isfield(opts.parallel_config, 'num_workers')
            cfg.stage09.parallel_num_workers = opts.parallel_config.num_workers;
        end
        if isfield(opts.parallel_config, 'auto_start_pool') && ~isempty(opts.parallel_config.auto_start_pool)
            cfg.stage09.auto_start_pool = logical(opts.parallel_config.auto_start_pool);
        end
    end

    if isfield(opts, 'disable_progress') && ~isempty(opts.disable_progress)
        cfg.stage09.disable_progress = logical(opts.disable_progress);
    end

    if isfield(opts, 'benchmark_mode') && logical(opts.benchmark_mode)
        cfg.stage09.write_csv = false;
        cfg.stage09.disable_progress = true;
        cfg.stage09.save_cache_file = false;
    end

    if isfield(opts, 'benchmark_h_grid_km') && ~isempty(opts.benchmark_h_grid_km)
        cfg.stage09.search_domain.h_grid_km = opts.benchmark_h_grid_km;
    end
    if isfield(opts, 'benchmark_i_grid_deg') && ~isempty(opts.benchmark_i_grid_deg)
        cfg.stage09.search_domain.i_grid_deg = opts.benchmark_i_grid_deg;
    end
    if isfield(opts, 'benchmark_P_grid') && ~isempty(opts.benchmark_P_grid)
        cfg.stage09.search_domain.P_grid = opts.benchmark_P_grid;
    end
    if isfield(opts, 'benchmark_T_grid') && ~isempty(opts.benchmark_T_grid)
        cfg.stage09.search_domain.T_grid = opts.benchmark_T_grid;
    end
    if isfield(opts, 'benchmark_case_limit') && ~isempty(opts.benchmark_case_limit)
        cfg.stage09.scan_case_limit = opts.benchmark_case_limit;
    end
end


function use_parallel = local_prepare_stage09_parallel(cfg, log_fid)
    use_parallel = false;

    if ~isfield(cfg.stage09, 'use_parallel') || ~cfg.stage09.use_parallel
        log_msg(log_fid, 'INFO', 'Parallel disabled by cfg.stage09.use_parallel=false.');
        return;
    end

    requested_profile = string(cfg.stage09.parallel_pool_profile);
    if isfield(cfg.stage09, 'prefer_thread_pool_for_batch') && cfg.stage09.prefer_thread_pool_for_batch && ...
            isfield(cfg.stage09, 'disable_progress') && cfg.stage09.disable_progress && ...
            requested_profile == "local"
        requested_profile = "threads";
        cfg.stage09.parallel_pool_profile = char(requested_profile);
    end

    try
        pool = gcp('nocreate');
        if isempty(pool) && cfg.stage09.auto_start_pool
            pool = ensure_parallel_pool(char(requested_profile), cfg.stage09.parallel_num_workers);
        end
        use_parallel = ~isempty(pool);
        if use_parallel
            log_msg(log_fid, 'INFO', 'Parallel pool ready. %s', ...
                get_parallel_pool_desc(pool, requested_profile));
        else
            log_msg(log_fid, 'INFO', 'No parallel pool available. Falling back to serial.');
        end
    catch ME
        use_parallel = false;
        log_msg(log_fid, 'INFO', 'Parallel unavailable. Falling back to serial. Reason: %s', ME.message);
    end
end


function trajs_in = local_build_demo_casebank_stage09(cfg)
% Reuse the Stage09.3 validation casebank builder logic:
%   - nominal all
%   - heading subset
%   - critical all
% and wrap each element into Stage02-family style.

    stage01_out = stage01_scenario_disk(cfg);
    casebank = stage01_out.casebank;

    nominal_cases = casebank.nominal(:);

    heading_cases = casebank.heading(:);
    if numel(heading_cases) > 10
        heading_cases = heading_cases(1:10);
    end

    critical_cases = casebank.critical(:);
    cases_all = [nominal_cases; heading_cases; critical_cases];
    nCase = numel(cases_all);

    if nCase < 1
        error('No cases selected for Stage09.4 scan.');
    end

    case_i = cases_all(1);
    traj_i = propagate_hgv_case_stage02(case_i, cfg);
    val_i  = validate_hgv_trajectory_stage02(traj_i, cfg);
    sum_i  = summarize_hgv_case_stage02(case_i, traj_i, val_i);

    first_item = struct();
    first_item.case = case_i;
    first_item.traj = traj_i;
    first_item.validation = val_i;
    first_item.summary = sum_i;

    trajs_in = repmat(first_item, nCase, 1);
    trajs_in(1) = first_item;

    for k = 2:nCase
        case_i = cases_all(k);
        traj_i = propagate_hgv_case_stage02(case_i, cfg);
        val_i  = validate_hgv_trajectory_stage02(traj_i, cfg);
        sum_i  = summarize_hgv_case_stage02(case_i, traj_i, val_i);

        trajs_in(k).case = case_i;
        trajs_in(k).traj = traj_i;
        trajs_in(k).validation = val_i;
        trajs_in(k).summary = sum_i;
    end
end


function T = local_build_search_domain_table_stage09(cfg)

    sd = cfg.stage09.search_domain;

    [H, I, P, TT] = ndgrid(sd.h_grid_km(:), sd.i_grid_deg(:), sd.P_grid(:), sd.T_grid(:));
    H = H(:);
    I = I(:);
    P = P(:);
    TT = TT(:);
    F = repmat(sd.F_fixed, size(H));
    Ns = P .* TT;

    T = table(H, I, P, TT, F, Ns, ...
        'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
    T = sortrows(T, {'Ns','h_km','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});
end
