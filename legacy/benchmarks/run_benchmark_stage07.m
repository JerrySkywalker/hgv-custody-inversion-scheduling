function report = run_benchmark_stage07(cfg)
    %RUN_BENCHMARK_STAGE07 Benchmark Stage07 heading-risk scan in serial vs parallel mode.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    [cfg, default_opts, default_mode] = rs_apply_parallel_policy('stage07', cfg, struct());
    [~, serial_opts] = rs_apply_parallel_policy('stage07', cfg, struct(), 'serial');
    [~, parallel_opts] = rs_apply_parallel_policy('stage07', cfg, struct(), 'parallel');

    cfg = local_apply_stage07_benchmark_overrides(cfg);
    default_opts = local_augment_scan_opts(default_opts);
    serial_opts = local_augment_scan_opts(serial_opts);
    parallel_opts = local_augment_scan_opts(parallel_opts);

    bench_cfg = struct();
    bench_cfg.stage_name = 'stage07';
    bench_cfg.benchmark_name = 'stage07_scan_heading_risk_map';
    bench_cfg.output_root = cfg.paths.benchmarks;
    bench_cfg.warmup_runs = cfg.benchmark.warmup_runs;
    bench_cfg.repeat = cfg.benchmark.stage07_repeat;
    bench_cfg.enable_kernel_prewarm = cfg.benchmark.enable_kernel_prewarm;
    bench_cfg.primary_timing_view = cfg.benchmark.primary_timing_view;
    bench_cfg.default_mode = default_mode;
    bench_cfg.default_opts = default_opts;
    bench_cfg.serial_opts = serial_opts;
    bench_cfg.parallel_opts = parallel_opts;
    bench_cfg.parallel_setup_fn = @local_prepare_stage07_parallel;
    bench_cfg.compare_opts = struct( ...
        'abs_tol', cfg.benchmark.default_abs_tol, ...
        'rel_tol', cfg.benchmark.default_rel_tol, ...
        'ignored_fields', {[cfg.benchmark.default_ignored_fields, {'cfg','files','detail_banks'}]});
    bench_cfg.save_opts = struct( ...
        'save_mat', cfg.benchmark.save_mat, ...
        'save_json', cfg.benchmark.save_json);
    bench_cfg.input_summary_fn = @local_stage07_input_summary;
    bench_cfg.notes = 'Stage07 heading-risk benchmark with reduced entry count and heading grid.';

    report = run_solver_benchmark(@stage07_scan_heading_risk_map, cfg, bench_cfg);

    fprintf('[benchmark] Stage07 primary view  : %s\n', report.timing.primary_view);
    fprintf('[benchmark] Stage07 cold serial   : %s\n', mat2str(report.timing.cold.serial_runs_s, 6));
    fprintf('[benchmark] Stage07 cold parallel : %s\n', mat2str(report.timing.cold.parallel_runs_s, 6));
    fprintf('[benchmark] Stage07 warm serial   : %s\n', mat2str(report.timing.warm.serial_runs_s, 6));
    fprintf('[benchmark] Stage07 warm parallel : %s\n', mat2str(report.timing.warm.parallel_runs_s, 6));
    fprintf('[benchmark] Stage07 parallel setup: %.6f s (excluded from run timing)\n', report.timing.parallel_setup_s);
    fprintf('[benchmark] Stage07 kernel prewarm serial   : %.6f s\n', report.timing.serial_kernel_prewarm_s);
    fprintf('[benchmark] Stage07 kernel prewarm parallel : %.6f s\n', report.timing.parallel_kernel_prewarm_s);
    fprintf('[benchmark] Stage07 serial best   : %.6f s\n', report.timing.serial_best_s);
    fprintf('[benchmark] Stage07 parallel best : %.6f s\n', report.timing.parallel_best_s);
    fprintf('[benchmark] Stage07 speedup(best) : %.4f x\n', report.timing.speedup_best);
    fprintf('[benchmark] Stage07 speedup(mean) : %.4f x\n', report.timing.speedup_mean);
    fprintf('[benchmark] Result check         : %s\n', report.compare.summary);
    fprintf('[benchmark] MAT report           : %s\n', report.paths.mat_file);
end

function cfg = local_apply_stage07_benchmark_overrides(cfg)
    cfg.stage07.entry_sampling.enable = true;
    cfg.stage07.entry_sampling.max_entry_count = cfg.benchmark.stage07_entry_count;
    cfg.stage07.heading_scan.step_deg = cfg.benchmark.stage07_heading_step_deg;
    cfg.stage07.heading_scan.max_abs_offset_deg = cfg.benchmark.stage07_heading_max_abs_offset_deg;
end

function opts = local_augment_scan_opts(opts)
    opts.disable_detail_bank = true;
    opts.benchmark_mode = true;
end

function summary = local_stage07_input_summary(cfg)
    summary = struct();
    summary.reference_source = 'latest_stage07_refwalker_cache';
    summary.scope_source = 'latest_stage07_scope_cache';
    summary.entry_count = cfg.stage07.entry_sampling.max_entry_count;
    summary.heading_step_deg = cfg.stage07.heading_scan.step_deg;
    summary.heading_max_abs_offset_deg = cfg.stage07.heading_scan.max_abs_offset_deg;
    if isfield(cfg, 'run_stages') && isfield(cfg.run_stages, 'parallel_modes')
        summary.default_mode = cfg.run_stages.parallel_modes.stage07;
    end
end

function local_prepare_stage07_parallel(~, opts)
    if ~isfield(opts, 'parallel_config') || ~opts.parallel_config.enabled
        return;
    end
    ensure_parallel_pool(opts.parallel_config.profile_name, opts.parallel_config.num_workers);
end
