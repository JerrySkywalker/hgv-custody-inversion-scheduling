function report = run_benchmark_stage09(cfg)
    %RUN_BENCHMARK_STAGE09 Benchmark Stage09 feasible-domain scan in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    serial_opts = struct('mode', 'serial');
    parallel_opts = struct('mode', 'parallel');
    default_mode = 'serial';

    serial_opts = local_augment_stage09_opts(serial_opts, cfg);
    parallel_opts = local_augment_stage09_opts(parallel_opts, cfg);

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage09';
    bench_cfg.benchmark_name = 'stage09_build_feasible_domain';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.stage09_repeat;
    bench_cfg.enable_kernel_prewarm = cfg.benchmark.enable_kernel_prewarm;
    bench_cfg.primary_timing_view = cfg.benchmark.primary_timing_view;
    bench_cfg.default_mode = default_mode;
    bench_cfg.default_opts = serial_opts;
    bench_cfg.serial_opts = serial_opts;
    bench_cfg.parallel_opts = parallel_opts;
    bench_cfg.parallel_setup_fn = @local_prepare_stage09_parallel;
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg','files'}]});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage09_input_summary;
    bench_cfg.notes = 'Stage09 feasible-domain benchmark on reduced search grid and casebank.';

    report = run_solver_benchmark(@stage09_build_feasible_domain, cfg, bench_cfg);

    fprintf('[benchmark] Stage09 primary view  : %s\n', report.timing.primary_view);
    fprintf('[benchmark] Stage09 cold serial   : %s\n', mat2str(report.timing.cold.serial_runs_s, 6));
    fprintf('[benchmark] Stage09 cold parallel : %s\n', mat2str(report.timing.cold.parallel_runs_s, 6));
    fprintf('[benchmark] Stage09 warm serial   : %s\n', mat2str(report.timing.warm.serial_runs_s, 6));
    fprintf('[benchmark] Stage09 warm parallel : %s\n', mat2str(report.timing.warm.parallel_runs_s, 6));
    fprintf('[benchmark] Stage09 speedup(best) : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Stage09 speedup(mean) : %.4f x\n', report.timing.speedup_mean);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function opts = local_augment_stage09_opts(opts, cfg)
    opts.disable_progress = true;
    opts.benchmark_mode = true;
    opts.benchmark_h_grid_km = cfg.benchmark.stage09_h_grid_km;
    opts.benchmark_i_grid_deg = cfg.benchmark.stage09_i_grid_deg;
    opts.benchmark_P_grid = cfg.benchmark.stage09_P_grid;
    opts.benchmark_T_grid = cfg.benchmark.stage09_T_grid;
    opts.benchmark_case_limit = cfg.benchmark.stage09_case_limit;
end

function summary = local_stage09_input_summary(cfg)
    summary = struct();
    summary.h_grid_km = cfg.benchmark.stage09_h_grid_km;
    summary.i_grid_deg = cfg.benchmark.stage09_i_grid_deg;
    summary.P_grid = cfg.benchmark.stage09_P_grid;
    summary.T_grid = cfg.benchmark.stage09_T_grid;
    summary.case_limit = cfg.benchmark.stage09_case_limit;
end

function local_prepare_stage09_parallel(~, opts)
    if ~isfield(opts, 'mode') || ~strcmpi(string(opts.mode), "parallel")
        return;
    end
    ensure_parallel_pool('threads', []);
end
