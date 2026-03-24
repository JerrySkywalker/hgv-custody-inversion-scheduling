function report = run_benchmark_stage03(cfg)
    %RUN_BENCHMARK_STAGE03 Benchmark Stage03 serial vs parallel execution with repeated runs.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    [cfg, default_opts, default_mode] = rs_apply_parallel_policy('stage03', cfg, struct());
    [~, serial_opts] = rs_apply_parallel_policy('stage03', cfg, struct(), 'serial');
    [~, parallel_opts] = rs_apply_parallel_policy('stage03', cfg, struct(), 'parallel');

    if cfg.benchmark.stage03_disable_plot
        cfg.stage03.make_plot = false;
    end
    if isfield(cfg.benchmark, 'stage03_disable_case_logging') && cfg.benchmark.stage03_disable_case_logging
        cfg.stage03.log_each_case = false;
    end

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage03';
    bench_cfg.benchmark_name = 'stage03_visibility_pipeline';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.stage03_repeat;
    bench_cfg.enable_kernel_prewarm = cfg.benchmark.enable_kernel_prewarm;
    bench_cfg.primary_timing_view = cfg.benchmark.primary_timing_view;
    bench_cfg.default_mode = default_mode;
    bench_cfg.default_opts = default_opts;
    bench_cfg.serial_opts = serial_opts;
    bench_cfg.parallel_opts = parallel_opts;
    bench_cfg.parallel_setup_fn = @local_prepare_stage03_parallel;
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg'}]});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage03_input_summary;
    bench_cfg.notes = 'Stage03 visibility pipeline benchmark with three repeated serial/parallel runs.';

    report = run_solver_benchmark(@stage03_visibility_pipeline, cfg, bench_cfg);

    fprintf('[benchmark] Stage03 primary view  : %s\n', report.timing.primary_view);
    fprintf('[benchmark] Stage03 cold serial   : %s\n', mat2str(report.timing.cold.serial_runs_s, 6));
    fprintf('[benchmark] Stage03 cold parallel : %s\n', mat2str(report.timing.cold.parallel_runs_s, 6));
    fprintf('[benchmark] Stage03 warm serial   : %s\n', mat2str(report.timing.warm.serial_runs_s, 6));
    fprintf('[benchmark] Stage03 warm parallel : %s\n', mat2str(report.timing.warm.parallel_runs_s, 6));
    fprintf('[benchmark] Stage03 parallel setup: %.6f s (excluded from run timing)\n', report.timing.parallel_setup_s);
    fprintf('[benchmark] Stage03 kernel prewarm serial   : %.6f s\n', report.timing.serial_kernel_prewarm_s);
    fprintf('[benchmark] Stage03 kernel prewarm parallel : %.6f s\n', report.timing.parallel_kernel_prewarm_s);
    fprintf('[benchmark] Stage03 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage03 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage03 speedup(best) : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Stage03 speedup(mean) : %.4f x\n', report.timing.speedup_mean);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function summary = local_stage03_input_summary(cfg)
    summary = struct();
    summary.stage02_source = 'latest_stage02_cache';
    summary.make_plot = cfg.stage03.make_plot;
    summary.max_range_km = cfg.stage03.max_range_km;
    summary.max_offnadir_deg = cfg.stage03.max_offnadir_deg;
    summary.walker = struct( ...
        'h_km', cfg.stage03.h_km, ...
        'i_deg', cfg.stage03.i_deg, ...
        'P', cfg.stage03.P, ...
        'T', cfg.stage03.T);
    if isfield(cfg, 'run_stages') && isfield(cfg.run_stages, 'parallel_modes')
        summary.default_mode = cfg.run_stages.parallel_modes.stage03;
    end
end

function local_prepare_stage03_parallel(~, opts)
    if ~isfield(opts, 'parallel_config') || ~opts.parallel_config.enabled
        return;
    end
    ensure_parallel_pool(opts.parallel_config.profile_name, opts.parallel_config.num_workers);
end
