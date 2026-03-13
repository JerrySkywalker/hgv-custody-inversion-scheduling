function report = run_benchmark_stage05(cfg)
    %RUN_BENCHMARK_STAGE05 Benchmark Stage05 nominal Walker search in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if cfg.benchmark.stage05_disable_live_progress
        cfg.stage05.use_live_progress = false;
        cfg.stage05.progress_every = inf;
    end
    if cfg.benchmark.stage05_disable_eval_bank
        cfg.stage05.save_eval_bank = false;
    end
    if cfg.benchmark.stage05_use_reduced_grid
        cfg.stage05.i_grid_deg = cfg.benchmark.stage05_i_grid_deg;
        cfg.stage05.P_grid = cfg.benchmark.stage05_P_grid;
        cfg.stage05.T_grid = cfg.benchmark.stage05_T_grid;
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage05';
    bench_cfg.benchmark_name = 'stage05_nominal_walker_search';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.repeat;
    bench_cfg.serial_opts = struct('mode', 'serial');
    bench_cfg.parallel_opts = struct('mode', 'parallel', 'parallel_config', struct( ...
        'enabled', true, ...
        'profile_name', cfg.stage05.parallel_pool_profile, ...
        'num_workers', cfg.stage05.parallel_num_workers, ...
        'auto_start_pool', cfg.stage05.auto_start_pool));
    bench_cfg.compare_opts = struct('abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg', 'walltime_s'}]});
    bench_cfg.save_opts = struct('save_mat', cfg.benchmark.save_mat, 'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage05_input_summary;
    bench_cfg.notes = 'Stage05 reduced-grid benchmark for serial/parallel regression tracking.';

    report = run_solver_benchmark(@stage05_nominal_walker_search, cfg, bench_cfg);

    fprintf('[benchmark] Stage05 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage05 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage05 speedup       : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage05_input_summary(cfg)
    summary = struct();
    summary.case_source = 'latest_stage02_and_stage04_cache';
    summary.i_grid_deg = cfg.stage05.i_grid_deg;
    summary.P_grid = cfg.stage05.P_grid;
    summary.T_grid = cfg.stage05.T_grid;
    summary.use_parallel = cfg.stage05.use_parallel;
end
