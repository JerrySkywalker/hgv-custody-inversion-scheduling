function report = run_benchmark_stage04(cfg)
    %RUN_BENCHMARK_STAGE04 Benchmark Stage04 worst-window scan in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if cfg.benchmark.stage04_disable_plot
        cfg.stage04.make_plot = false;
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage04';
    bench_cfg.benchmark_name = 'stage04_window_worstcase';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.repeat;
    bench_cfg.serial_opts = struct('mode', 'serial');
    bench_cfg.parallel_opts = struct('mode', 'parallel', 'parallel_config', struct( ...
        'enabled', true, ...
        'profile_name', cfg.stage04.parallel_pool_profile, ...
        'num_workers', cfg.stage04.parallel_num_workers, ...
        'auto_start_pool', cfg.stage04.auto_start_pool));
    bench_cfg.compare_opts = struct('abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg'}]});
    bench_cfg.save_opts = struct('save_mat', cfg.benchmark.save_mat, 'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage04_input_summary;
    bench_cfg.notes = 'Stage04 window benchmark for serial/parallel regression tracking.';

    report = run_solver_benchmark(@stage04_window_worstcase, cfg, bench_cfg);

    fprintf('[benchmark] Stage04 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage04 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage04 speedup       : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage04_input_summary(cfg)
    summary = struct();
    summary.case_source = 'latest_stage03_cache';
    summary.make_plot = cfg.stage04.make_plot;
    summary.Tw_s = cfg.stage04.Tw_s;
    summary.window_step_s = cfg.stage04.window_step_s;
end
