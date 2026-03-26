function result_rows = run_design_grid_search_parallel(rows, trajs_in, engine_mode, engine_cfg, search_spec, logger, parallel_opts)
n = numel(rows);
result_cells = cell(n, 1);

if parallel_opts.use_parallel
    pool = gcp('nocreate');
    if isempty(pool)
        if isempty(parallel_opts.num_workers)
            pool = parpool(parallel_opts.pool_profile);
        else
            pool = parpool(parallel_opts.pool_profile, parallel_opts.num_workers);
        end
    end

    gamma_eff_scalar = search_spec.gamma_eff_scalar;
    source_kind = search_spec.source_kind;
    mon = build_parallel_monitor_options(search_spec);

    dq = [];
    if mon.enable_monitor && mon.enable_dataqueue
        dq = parallel.pool.DataQueue;
        afterEach(dq, @(msg) local_handle_parallel_event(msg, logger, mon));
    end

    t_parallel = tic;
    bytes_supported = false;
    if mon.enable_monitor && mon.enable_comm_bytes
        try
            ticBytes(pool);
            bytes_supported = true;
        catch
            bytes_supported = false;
        end
    end

    if mon.enable_monitor
        log_message(logger, 'INFO', ...
            'Parallel monitor started: n_rows=%d, workers=%d, mode=%s, slow_iter_warn=%d, threshold=%.3f s', ...
            n, pool.NumWorkers, engine_mode, mon.enable_slow_iter_warn, mon.slow_iter_threshold_sec);
    end

    parfor k = 1:n
        row = rows(k);
        t_iter = tic;

        eval_out = local_eval_parallel_row( ...
            row, trajs_in, engine_mode, gamma_eff_scalar, engine_cfg);

        iter_time_sec = toc(t_iter);

        packed = local_pack_parallel_row( ...
            row, eval_out, engine_mode, gamma_eff_scalar, source_kind);

        if ~isfield(packed, 'iter_time_sec')
            packed.iter_time_sec = iter_time_sec;
        end

        task = getCurrentTask();
        worker_id = NaN;
        if ~isempty(task)
            worker_id = task.ID;
        end

        if mon.enable_monitor && mon.enable_dataqueue && mon.enable_per_point_debug
            msg = struct();
            msg.kind = 'point_completed';
            msg.worker_id = worker_id;
            msg.k = k;
            msg.design_id = local_design_id_string(row);
            msg.iter_time_sec = iter_time_sec;
            msg.level = mon.per_point_log_level;
            msg.P = local_get_row_field(row, 'P', NaN);
            msg.T = local_get_row_field(row, 'T', NaN);
            msg.i_deg = local_get_row_field(row, 'i_deg', NaN);
            msg.Ns = local_get_row_field(row, 'Ns', NaN);
            send(dq, msg);
        end

        if mon.enable_slow_iter_warn && iter_time_sec > mon.slow_iter_threshold_sec
            packed.parallel_warn_flag = true;
            packed.parallel_warn_worker_id = worker_id;
            packed.parallel_warn_message = sprintf( ...
                'Slow parallel iteration: worker=%g, k=%d, design_id=%s, iter_time=%.3f s', ...
                worker_id, k, local_design_id_string(row), iter_time_sec);
        else
            packed.parallel_warn_flag = false;
            packed.parallel_warn_worker_id = NaN;
            packed.parallel_warn_message = "";
        end

        result_cells{k} = packed;
    end

    parallel_time_sec = toc(t_parallel);

    if mon.enable_monitor
        if bytes_supported
            try
                bytes_info = tocBytes(pool);
                total_mb = local_extract_total_megabytes(bytes_info);
                log_message(logger, 'INFO', ...
                    'Parallel search branch completed: n_rows=%d, elapsed=%.3f s, comm_total=%.3f MB', ...
                    n, parallel_time_sec, total_mb);
            catch
                log_message(logger, 'INFO', ...
                    'Parallel search branch completed: n_rows=%d, elapsed=%.3f s', ...
                    n, parallel_time_sec);
            end
        else
            log_message(logger, 'INFO', ...
                'Parallel search branch completed: n_rows=%d, elapsed=%.3f s', ...
                n, parallel_time_sec);
        end
    else
        log_message(logger, 'INFO', 'Parallel search branch completed: n_rows=%d', n);
    end
else
    error('run_design_grid_search_parallel:ParallelDisabled', ...
        'Parallel helper called while parallel mode is disabled.');
end

result_rows = vertcat(result_cells{:});

if parallel_opts.use_parallel
    mon = build_parallel_monitor_options(search_spec);
    if mon.enable_monitor && mon.enable_slow_iter_warn
        warn_mask = false(size(result_rows));
        for i = 1:numel(result_rows)
            if isfield(result_rows(i), 'parallel_warn_flag') && result_rows(i).parallel_warn_flag
                warn_mask(i) = true;
            end
        end

        n_warn = nnz(warn_mask);
        if n_warn > 0
            log_message(logger, 'WARN', ...
                'Parallel slow-iteration warnings detected: %d/%d rows exceeded %.3f s', ...
                n_warn, numel(result_rows), mon.slow_iter_threshold_sec);

            warn_rows = result_rows(warn_mask);
            for i = 1:numel(warn_rows)
                if isfield(warn_rows(i), 'parallel_warn_message')
                    log_message(logger, 'WARN', '%s', warn_rows(i).parallel_warn_message);
                end
            end
        end
    end
end
end

function eval_out = local_eval_parallel_row(row, trajs_in, engine_mode, gamma_eff_scalar, engine_cfg)
switch engine_mode
    case 'opend'
        eval_out = evaluate_design_point_opend(row, trajs_in, gamma_eff_scalar, engine_cfg);
    case 'closedd'
        eval_out = evaluate_design_point_closedd(row, trajs_in, gamma_eff_scalar, engine_cfg);
    otherwise
        error('run_design_grid_search_parallel:UnsupportedMode', ...
            'Unsupported evaluator mode: %s', engine_mode);
end
end

function packed = local_pack_parallel_row(row, eval_out, engine_mode, gamma_eff_scalar, source_kind)
packed = row;
eval_fields = fieldnames(eval_out);
for i = 1:numel(eval_fields)
    f = eval_fields{i};
    packed.(f) = eval_out.(f);
end

if ~isfield(packed, 'gamma_eff_scalar')
    packed.gamma_eff_scalar = gamma_eff_scalar;
end
if ~isfield(packed, 'engine_mode')
    packed.engine_mode = string(engine_mode);
end
if ~isfield(packed, 'source_kind')
    packed.source_kind = string(source_kind);
end
end

function total_mb = local_extract_total_megabytes(bytes_info)
total_bytes = 0;

if isnumeric(bytes_info)
    total_bytes = sum(bytes_info(:), 'omitnan');
elseif isstruct(bytes_info)
    fns = fieldnames(bytes_info);
    for i = 1:numel(fns)
        v = bytes_info.(fns{i});
        if isnumeric(v)
            total_bytes = total_bytes + sum(v(:), 'omitnan');
        end
    end
end

total_mb = total_bytes / (1024^2);
end

function s = local_design_id_string(row)
s = "<unknown>";
if isstruct(row)
    if isfield(row, 'design_id') && ~isempty(row.design_id)
        s = char(string(row.design_id));
    elseif isfield(row, 'base_design_id') && ~isempty(row.base_design_id)
        s = char(string(row.base_design_id));
    end
end
end

function v = local_get_row_field(row, field_name, default_value)
v = default_value;
if isstruct(row) && isfield(row, field_name) && ~isempty(row.(field_name))
    v = row.(field_name);
end
end

function local_handle_parallel_event(msg, logger, mon)
if ~isstruct(msg) || ~isfield(msg, 'kind')
    return;
end

switch msg.kind
    case 'point_completed'
        log_message(logger, mon.per_point_log_level, ...
            'Parallel point completed: worker=%g, k=%d, design_id=%s, iter_time=%.3f s, P=%g, T=%g, i=%g, Ns=%g', ...
            msg.worker_id, msg.k, msg.design_id, msg.iter_time_sec, ...
            msg.P, msg.T, msg.i_deg, msg.Ns);
end
end
