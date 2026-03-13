function report = run_benchmark_stage01(cfg)
    %RUN_BENCHMARK_STAGE01 Benchmark Stage01 casebank construction in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if cfg.benchmark.stage01_disable_plot
        cfg.stage01.make_plot = false;
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage01';
    bench_cfg.benchmark_name = 'stage01_scenario_disk';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.repeat;
    bench_cfg.serial_opts = struct('mode', 'serial');
    bench_cfg.parallel_opts = struct( ...
        'mode', 'parallel', ...
        'parallel_config', struct( ...
            'enabled', true, ...
            'profile_name', cfg.stage01.parallel_pool_profile, ...
            'num_workers', cfg.stage01.parallel_num_workers, ...
            'auto_start_pool', cfg.stage01.auto_start_pool));
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {cfg.benchmark.default_ignored_fields});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage01_input_summary;
    bench_cfg.notes = 'Stage01 casebank baseline benchmark for serial/parallel regression tracking.';

    report = run_solver_benchmark(@stage01_scenario_disk, cfg, bench_cfg);

    fprintf('[benchmark] Stage01 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage01 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage01 speedup       : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage01_input_summary(cfg)
    summary = struct();
    summary.scene_mode = cfg.meta.scene_mode;
    summary.nominal_count = cfg.stage01.num_nominal_entry_points;
    summary.heading_offsets_deg = cfg.stage01.heading_offsets_deg;
    summary.make_plot = cfg.stage01.make_plot;
end
