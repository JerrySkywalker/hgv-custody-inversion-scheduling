function report = run_benchmark_stage05(cfg)
    %RUN_BENCHMARK_STAGE05 Benchmark Stage05 nominal Walker search in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    [cfg, default_opts, default_mode] = rs_apply_parallel_policy('stage05', cfg, struct());
    [~, serial_opts] = rs_apply_parallel_policy('stage05', cfg, struct(), 'serial');
    [~, parallel_opts] = rs_apply_parallel_policy('stage05', cfg, struct(), 'parallel');

    cfg = local_apply_stage05_benchmark_overrides(cfg);
    default_opts = local_augment_search_opts(default_opts);
    serial_opts = local_augment_search_opts(serial_opts);
    parallel_opts = local_augment_search_opts(parallel_opts);

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage05';
    bench_cfg.benchmark_name = 'stage05_nominal_walker_search';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.stage05_repeat;
    bench_cfg.enable_kernel_prewarm = cfg.benchmark.enable_kernel_prewarm;
    bench_cfg.primary_timing_view = cfg.benchmark.primary_timing_view;
    bench_cfg.default_mode = default_mode;
    bench_cfg.default_opts = default_opts;
    bench_cfg.serial_opts = serial_opts;
    bench_cfg.parallel_opts = parallel_opts;
    bench_cfg.parallel_setup_fn = @local_prepare_stage05_parallel;
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg','log_file','table_file','feasible_table_file', ...
            'stage02_file','stage04_file','summary','grid','feasible_grid','eval_bank'}]});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage05_input_summary;
    bench_cfg.notes = 'Stage05 nominal Walker search benchmark with fixed reduced grid and serial/parallel comparison.';

    report = run_solver_benchmark(@stage05_nominal_walker_search, cfg, bench_cfg);

    fprintf('[benchmark] Stage05 primary view  : %s\n', report.timing.primary_view);
    fprintf('[benchmark] Stage05 cold serial   : %s\n', mat2str(report.timing.cold.serial_runs_s, 6));
    fprintf('[benchmark] Stage05 cold parallel : %s\n', mat2str(report.timing.cold.parallel_runs_s, 6));
    fprintf('[benchmark] Stage05 warm serial   : %s\n', mat2str(report.timing.warm.serial_runs_s, 6));
    fprintf('[benchmark] Stage05 warm parallel : %s\n', mat2str(report.timing.warm.parallel_runs_s, 6));
    fprintf('[benchmark] Stage05 parallel setup: %.6f s (excluded from run timing)\n', report.timing.parallel_setup_s);
    fprintf('[benchmark] Stage05 kernel prewarm serial   : %.6f s\n', report.timing.serial_kernel_prewarm_s);
    fprintf('[benchmark] Stage05 kernel prewarm parallel : %.6f s\n', report.timing.parallel_kernel_prewarm_s);
    fprintf('[benchmark] Stage05 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage05 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage05 speedup(best) : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Stage05 speedup(mean) : %.4f x\n', report.timing.speedup_mean);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function cfg = local_apply_stage05_benchmark_overrides(cfg)
    cfg.stage05.use_live_progress = false;
    cfg.stage05.save_eval_bank = false;
    cfg.stage05.make_plot = false;
    cfg.stage05.use_early_stop = false;
    cfg.stage05.i_grid_deg = cfg.benchmark.stage05_i_grid_deg(:).';
    cfg.stage05.P_grid = cfg.benchmark.stage05_P_grid(:).';
    cfg.stage05.T_grid = cfg.benchmark.stage05_T_grid(:).';
end

function opts = local_augment_search_opts(opts)
    opts.disable_live_progress = true;
    opts.disable_eval_bank = true;
    opts.benchmark_mode = true;
end

function summary = local_stage05_input_summary(cfg)
    summary = struct();
    summary.stage02_source = 'latest_stage02_cache';
    summary.stage04_source = 'latest_stage04_cache';
    summary.i_grid_deg = cfg.stage05.i_grid_deg;
    summary.P_grid = cfg.stage05.P_grid;
    summary.T_grid = cfg.stage05.T_grid;
    summary.use_early_stop = cfg.stage05.use_early_stop;
    if isfield(cfg, 'run_stages') && isfield(cfg.run_stages, 'parallel_modes')
        summary.default_mode = cfg.run_stages.parallel_modes.stage05;
    end
end

function local_prepare_stage05_parallel(~, opts)
    if ~isfield(opts, 'parallel_config') || ~opts.parallel_config.enabled
        return;
    end
    ensure_parallel_pool(opts.parallel_config.profile_name, opts.parallel_config.num_workers);
end
