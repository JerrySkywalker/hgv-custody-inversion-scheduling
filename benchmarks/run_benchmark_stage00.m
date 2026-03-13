function report = run_benchmark_stage00(cfg)
    %RUN_BENCHMARK_STAGE00 Benchmark Stage00 serial vs parallel execution with result regression checks.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage00';
    bench_cfg.benchmark_name = 'stage00_bootstrap';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.repeat;
    bench_cfg.serial_opts = struct('mode', 'serial');
    bench_cfg.parallel_opts = struct( ...
        'mode', 'parallel', ...
        'parallel_config', struct( ...
            'enabled', true, ...
            'profile_name', 'local', ...
            'num_workers', [], ...
            'auto_start_pool', true));
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {cfg.benchmark.default_ignored_fields});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage00_input_summary;
    bench_cfg.notes = 'Stage00 baseline benchmark for future parallel-refactor regression tracking.';

    report = run_solver_benchmark(@stage00_bootstrap, cfg, bench_cfg);

    fprintf('[benchmark] Stage00 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage00 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage00 speedup       : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage00_input_summary(cfg)
    summary = struct();
    summary.project_name = cfg.project_name;
    summary.random_seed = cfg.random.seed;
    summary.result_root = cfg.paths.results;
end
