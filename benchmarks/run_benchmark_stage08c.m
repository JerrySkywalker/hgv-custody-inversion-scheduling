function report = run_benchmark_stage08c(cfg)
    %RUN_BENCHMARK_STAGE08C Benchmark Stage08 boundary sensitivity in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    serial_opts = struct('mode', 'serial');
    parallel_opts = struct('mode', 'parallel');
    default_mode = 'serial';

    serial_opts = local_augment_stage08c_opts(serial_opts, cfg);
    parallel_opts = local_augment_stage08c_opts(parallel_opts, cfg);

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage08c';
    bench_cfg.benchmark_name = 'stage08_boundary_window_sensitivity';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.stage08c_repeat;
    bench_cfg.enable_kernel_prewarm = cfg.benchmark.enable_kernel_prewarm;
    bench_cfg.primary_timing_view = cfg.benchmark.primary_timing_view;
    bench_cfg.default_mode = default_mode;
    bench_cfg.default_opts = serial_opts;
    bench_cfg.serial_opts = serial_opts;
    bench_cfg.parallel_opts = parallel_opts;
    bench_cfg.parallel_setup_fn = @local_prepare_stage08c_parallel;
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, ...
            {'cfg','files','figures','summary_table','pool_info'}]});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage08c_input_summary;
    bench_cfg.notes = 'Stage08c boundary sensitivity benchmark with reduced weak-side grid and Tw counts.';

    report = run_solver_benchmark(@stage08_boundary_window_sensitivity, cfg, bench_cfg);

    fprintf('[benchmark] Stage08c primary view  : %s\n', report.timing.primary_view);
    fprintf('[benchmark] Stage08c cold serial   : %s\n', mat2str(report.timing.cold.serial_runs_s, 6));
    fprintf('[benchmark] Stage08c cold parallel : %s\n', mat2str(report.timing.cold.parallel_runs_s, 6));
    fprintf('[benchmark] Stage08c warm serial   : %s\n', mat2str(report.timing.warm.serial_runs_s, 6));
    fprintf('[benchmark] Stage08c warm parallel : %s\n', mat2str(report.timing.warm.parallel_runs_s, 6));
    fprintf('[benchmark] Stage08c speedup(best) : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Stage08c speedup(mean) : %.4f x\n', report.timing.speedup_mean);
    fprintf('[benchmark] Result check          : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report            : %s\n', report.paths.mat_file);
end

function opts = local_augment_stage08c_opts(opts, cfg)
    opts.disable_progress = true;
    opts.benchmark_mode = true;
    opts.benchmark_max_tw_count = cfg.benchmark.stage08c_max_tw_count;
    opts.benchmark_h_km_list = cfg.benchmark.stage08c_h_km_list;
    opts.benchmark_i_deg_list = cfg.benchmark.stage08c_i_deg_list;
    opts.benchmark_PT_pairs = cfg.benchmark.stage08c_PT_pairs;
end

function summary = local_stage08c_input_summary(cfg)
    summary = struct();
    summary.h_km_list = cfg.benchmark.stage08c_h_km_list;
    summary.i_deg_list = cfg.benchmark.stage08c_i_deg_list;
    summary.PT_pairs = cfg.benchmark.stage08c_PT_pairs;
    summary.max_tw_count = cfg.benchmark.stage08c_max_tw_count;
end

function local_prepare_stage08c_parallel(~, opts)
    if ~isfield(opts, 'mode') || ~strcmpi(string(opts.mode), "parallel")
        return;
    end
    ensure_parallel_pool('threads', []);
end
