function report = run_benchmark_stage02(cfg)
    %RUN_BENCHMARK_STAGE02 Benchmark Stage02 trajectory propagation in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if cfg.benchmark.stage02_disable_plot
        cfg.stage02.make_plot = false;
        cfg.stage02.make_plot_3d = false;
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage02';
    bench_cfg.benchmark_name = 'stage02_hgv_nominal';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.repeat;
    bench_cfg.serial_opts = struct('mode', 'serial');
    bench_cfg.parallel_opts = struct('mode', 'parallel', 'parallel_config', struct( ...
        'enabled', true, ...
        'profile_name', cfg.stage02.parallel_pool_profile, ...
        'num_workers', cfg.stage02.parallel_num_workers, ...
        'auto_start_pool', cfg.stage02.auto_start_pool));
    bench_cfg.compare_opts = struct('abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg'}]});
    bench_cfg.save_opts = struct('save_mat', cfg.benchmark.save_mat, 'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage02_input_summary;
    bench_cfg.notes = 'Stage02 trajectory-bank benchmark for serial/parallel regression tracking.';

    report = run_solver_benchmark(@stage02_hgv_nominal, cfg, bench_cfg);

    fprintf('[benchmark] Stage02 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage02 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage02 speedup       : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage02_input_summary(cfg)
    summary = struct();
    summary.case_source = 'latest_stage01_cache';
    summary.make_plot = cfg.stage02.make_plot;
    summary.make_plot_3d = cfg.stage02.make_plot_3d;
    summary.Tmax_s = cfg.stage02.Tmax_s;
    summary.Ts_s = cfg.stage02.Ts_s;
end
