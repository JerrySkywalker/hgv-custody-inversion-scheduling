function report = run_solver_benchmark(solver_fn, input_value, bench_cfg)
    %RUN_SOLVER_BENCHMARK Run serial/parallel benchmark, compare outputs, and save traceable reports.

    if nargin < 3
        error('run_solver_benchmark requires solver_fn, input_value, and bench_cfg.');
    end

    bench_cfg = local_normalize_bench_cfg(bench_cfg);

    for iWarmup = 1:bench_cfg.warmup_runs
        solver_fn(input_value, bench_cfg.serial_opts);
        solver_fn(input_value, bench_cfg.parallel_opts);
    end

    serial_elapsed = inf(bench_cfg.repeat, 1);
    parallel_elapsed = inf(bench_cfg.repeat, 1);
    serial_result = [];
    parallel_result = [];

    for iRep = 1:bench_cfg.repeat
        t0 = tic;
        serial_result = solver_fn(input_value, bench_cfg.serial_opts);
        serial_elapsed(iRep) = toc(t0);

        t0 = tic;
        parallel_result = solver_fn(input_value, bench_cfg.parallel_opts);
        parallel_elapsed(iRep) = toc(t0);
    end

    cmp = bench_cfg.compare_fn(serial_result, parallel_result, bench_cfg.compare_opts);

    report = struct();
    report.stage_name = bench_cfg.stage_name;
    report.benchmark_name = bench_cfg.benchmark_name;
    report.run_id = sprintf('%s_%s', bench_cfg.benchmark_name, datestr(now, 'yyyymmdd_HHMMSS'));
    report.system = benchmark_collect_system_info();
    report.input_summary = bench_cfg.input_summary_fn(input_value);
    report.serial = benchmark_make_run_record('serial', bench_cfg.serial_opts, min(serial_elapsed), serial_result);
    report.parallel = benchmark_make_run_record('parallel', bench_cfg.parallel_opts, min(parallel_elapsed), parallel_result);
    report.timing = struct( ...
        'serial_runs_s', serial_elapsed, ...
        'parallel_runs_s', parallel_elapsed, ...
        'serial_best_s', min(serial_elapsed), ...
        'parallel_best_s', min(parallel_elapsed), ...
        'speedup_best', min(serial_elapsed) / min(parallel_elapsed), ...
        'speedup_mean', mean(serial_elapsed) / mean(parallel_elapsed));
    report.compare = cmp;
    report.paths = struct('output_dir', fullfile(bench_cfg.output_root, bench_cfg.stage_name));
    report.notes = bench_cfg.notes;

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
end

function summary = local_default_input_summary(input_value)
    if isstruct(input_value)
        summary = struct('class', class(input_value), 'fields', {fieldnames(input_value)});
    else
        summary = struct('class', class(input_value), 'size', size(input_value));
    end
end
