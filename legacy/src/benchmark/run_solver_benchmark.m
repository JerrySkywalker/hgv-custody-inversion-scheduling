function report = run_solver_benchmark(solver_fn, input_value, bench_cfg)
    %RUN_SOLVER_BENCHMARK Run serial/parallel benchmark, compare outputs, and save traceable reports.

    if nargin < 3
        error('run_solver_benchmark requires solver_fn, input_value, and bench_cfg.');
    end

    bench_cfg = local_normalize_bench_cfg(bench_cfg);

    serial_setup_s = 0;
    parallel_setup_s = 0;
    serial_kernel_prewarm_s = 0;
    parallel_kernel_prewarm_s = 0;

    if ~isempty(bench_cfg.serial_setup_fn)
        t_setup = tic;
        bench_cfg.serial_setup_fn(input_value, bench_cfg.serial_opts);
        serial_setup_s = toc(t_setup);
    end
    if ~isempty(bench_cfg.parallel_setup_fn)
        t_setup = tic;
        bench_cfg.parallel_setup_fn(input_value, bench_cfg.parallel_opts);
        parallel_setup_s = toc(t_setup);
    end

    for iWarmup = 1:bench_cfg.warmup_runs
        solver_fn(input_value, bench_cfg.serial_opts);
        solver_fn(input_value, bench_cfg.parallel_opts);
    end

    serial_elapsed_cold = inf(bench_cfg.repeat, 1);
    parallel_elapsed_cold = inf(bench_cfg.repeat, 1);
    serial_elapsed_warm = inf(bench_cfg.repeat, 1);
    parallel_elapsed_warm = inf(bench_cfg.repeat, 1);
    serial_result = [];
    parallel_result = [];

    for iRep = 1:bench_cfg.repeat
        t0 = tic;
        serial_result = solver_fn(input_value, bench_cfg.serial_opts);
        serial_elapsed_cold(iRep) = toc(t0);

        t0 = tic;
        parallel_result = solver_fn(input_value, bench_cfg.parallel_opts);
        parallel_elapsed_cold(iRep) = toc(t0);
    end

    if bench_cfg.enable_kernel_prewarm
        t0 = tic;
        serial_result = solver_fn(input_value, bench_cfg.serial_opts);
        serial_kernel_prewarm_s = toc(t0);

        t0 = tic;
        parallel_result = solver_fn(input_value, bench_cfg.parallel_opts);
        parallel_kernel_prewarm_s = toc(t0);

        for iRep = 1:bench_cfg.repeat
            t0 = tic;
            serial_result = solver_fn(input_value, bench_cfg.serial_opts);
            serial_elapsed_warm(iRep) = toc(t0);

            t0 = tic;
            parallel_result = solver_fn(input_value, bench_cfg.parallel_opts);
            parallel_elapsed_warm(iRep) = toc(t0);
        end
    else
        serial_elapsed_warm = serial_elapsed_cold;
        parallel_elapsed_warm = parallel_elapsed_cold;
    end

    cmp = bench_cfg.compare_fn(serial_result, parallel_result, bench_cfg.compare_opts);

    report = struct();
    report.stage_name = bench_cfg.stage_name;
    report.benchmark_name = bench_cfg.benchmark_name;
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    report.run_id = sprintf('%s_%s', bench_cfg.benchmark_name, timestamp);
    report.system = benchmark_collect_system_info();
    report.input_summary = bench_cfg.input_summary_fn(input_value);
    if isfield(bench_cfg, 'default_mode') && ~isempty(bench_cfg.default_mode)
        report.default_mode = char(string(bench_cfg.default_mode));
    end
    if isfield(bench_cfg, 'default_opts') && ~isempty(bench_cfg.default_opts)
        report.default = benchmark_make_run_record('default', bench_cfg.default_opts, NaN, []);
    end
    report.serial = benchmark_make_run_record('serial', bench_cfg.serial_opts, min(serial_elapsed_warm), serial_result);
    report.parallel = benchmark_make_run_record('parallel', bench_cfg.parallel_opts, min(parallel_elapsed_warm), parallel_result);
    report.timing = struct( ...
        'serial_setup_s', serial_setup_s, ...
        'parallel_setup_s', parallel_setup_s, ...
        'serial_kernel_prewarm_s', serial_kernel_prewarm_s, ...
        'parallel_kernel_prewarm_s', parallel_kernel_prewarm_s, ...
        'primary_view', char(string(bench_cfg.primary_timing_view)), ...
        'cold', local_make_timing_view(serial_elapsed_cold, parallel_elapsed_cold), ...
        'warm', local_make_timing_view(serial_elapsed_warm, parallel_elapsed_warm));
    report.timing.serial_runs_s = report.timing.(report.timing.primary_view).serial_runs_s;
    report.timing.parallel_runs_s = report.timing.(report.timing.primary_view).parallel_runs_s;
    report.timing.serial_best_s = report.timing.(report.timing.primary_view).serial_best_s;
    report.timing.parallel_best_s = report.timing.(report.timing.primary_view).parallel_best_s;
    report.timing.speedup_best = report.timing.(report.timing.primary_view).speedup_best;
    report.timing.speedup_mean = report.timing.(report.timing.primary_view).speedup_mean;
    report.compare = cmp;
    report.paths = struct('output_dir', fullfile(bench_cfg.output_root, bench_cfg.stage_name));
    report.notes = bench_cfg.notes;
    report.benchmark_guidance = struct( ...
        'primary_view', char(string(bench_cfg.primary_timing_view)), ...
        'rationale', local_make_primary_view_rationale(bench_cfg.primary_timing_view));

    saved = benchmark_save_report(report, bench_cfg.save_opts);
    report.paths.mat_file = saved.mat_file;
    report.paths.json_file = saved.json_file;
end

function bench_cfg = local_normalize_bench_cfg(bench_cfg)
    required_fields = {'stage_name', 'benchmark_name', 'serial_opts', 'parallel_opts', 'output_root'};
    for iField = 1:numel(required_fields)
        if ~isfield(bench_cfg, required_fields{iField})
            error('run_solver_benchmark:missingField', 'Missing bench_cfg.%s.', required_fields{iField});
        end
    end

    if ~isfield(bench_cfg, 'warmup_runs') || isempty(bench_cfg.warmup_runs)
        bench_cfg.warmup_runs = 0;
    end
    if ~isfield(bench_cfg, 'repeat') || isempty(bench_cfg.repeat)
        bench_cfg.repeat = 1;
    end
    if ~isfield(bench_cfg, 'compare_opts') || isempty(bench_cfg.compare_opts)
        bench_cfg.compare_opts = struct();
    end
    if ~isfield(bench_cfg, 'compare_fn') || isempty(bench_cfg.compare_fn)
        bench_cfg.compare_fn = @benchmark_compare_results;
    end
    if ~isfield(bench_cfg, 'input_summary_fn') || isempty(bench_cfg.input_summary_fn)
        bench_cfg.input_summary_fn = @local_default_input_summary;
    end
    if ~isfield(bench_cfg, 'notes') || isempty(bench_cfg.notes)
        bench_cfg.notes = '';
    end
    if ~isfield(bench_cfg, 'save_opts') || isempty(bench_cfg.save_opts)
        bench_cfg.save_opts = struct();
    end
    if ~isfield(bench_cfg, 'serial_setup_fn')
        bench_cfg.serial_setup_fn = [];
    end
    if ~isfield(bench_cfg, 'parallel_setup_fn')
        bench_cfg.parallel_setup_fn = [];
    end
    if ~isfield(bench_cfg, 'enable_kernel_prewarm') || isempty(bench_cfg.enable_kernel_prewarm)
        bench_cfg.enable_kernel_prewarm = true;
    end
    if ~isfield(bench_cfg, 'primary_timing_view') || isempty(bench_cfg.primary_timing_view)
        bench_cfg.primary_timing_view = 'cold';
    end
end

function summary = local_default_input_summary(input_value)
    if isstruct(input_value)
        summary = struct('class', class(input_value), 'fields', {fieldnames(input_value)});
    else
        summary = struct('class', class(input_value), 'size', size(input_value));
    end
end

function timing_view = local_make_timing_view(serial_runs_s, parallel_runs_s)
    timing_view = struct( ...
        'serial_runs_s', serial_runs_s, ...
        'parallel_runs_s', parallel_runs_s, ...
        'serial_best_s', min(serial_runs_s), ...
        'parallel_best_s', min(parallel_runs_s), ...
        'speedup_best', min(serial_runs_s) / min(parallel_runs_s), ...
        'speedup_mean', mean(serial_runs_s) / mean(parallel_runs_s));
end

function rationale = local_make_primary_view_rationale(primary_view)
    view_name = lower(char(string(primary_view)));
    switch view_name
        case 'cold'
            rationale = ['Cold timing is the recommended decision metric for one-shot ', ...
                'end-to-end experiment runs because it preserves first-run worker/code cold-start cost.'];
        case 'warm'
            rationale = ['Warm timing is the recommended decision metric for steady-state kernel analysis ', ...
                'because it excludes first-run worker/code cold-start cost.'];
        otherwise
            rationale = 'Primary timing view selected by benchmark configuration.';
    end
end
