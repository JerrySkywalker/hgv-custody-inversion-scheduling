function result_rows = run_design_grid_search_parallel(rows, trajs_in, engine_mode, engine_cfg, search_spec, logger, parallel_opts)
n = numel(rows);
result_cells = cell(n, 1);

if parallel_opts.use_parallel
    pool = gcp('nocreate');
    if isempty(pool)
        if isempty(parallel_opts.num_workers)
            parpool(parallel_opts.pool_profile);
        else
            parpool(parallel_opts.pool_profile, parallel_opts.num_workers);
        end
    end

    gamma_eff_scalar = search_spec.gamma_eff_scalar;
    source_kind = search_spec.source_kind;

    parfor k = 1:n
        row = rows(k);

        switch engine_mode
            case 'opend'
                packed = local_pack_parallel_row( ...
                    row, evaluate_design_point_opend(row, trajs_in, gamma_eff_scalar, engine_cfg), ...
                    engine_mode, gamma_eff_scalar, source_kind);
            case 'closedd'
                packed = local_pack_parallel_row( ...
                    row, evaluate_design_point_closedd(row, trajs_in, gamma_eff_scalar, engine_cfg), ...
                    engine_mode, gamma_eff_scalar, source_kind);
            otherwise
                error('run_design_grid_search_parallel:UnsupportedMode', ...
                    'Unsupported evaluator mode: %s', engine_mode);
        end

        result_cells{k} = packed;
    end

    log_message(logger, 'INFO', 'Parallel search branch completed: n_rows=%d', n);
else
    error('run_design_grid_search_parallel:ParallelDisabled', ...
        'Parallel helper called while parallel mode is disabled.');
end

result_rows = vertcat(result_cells{:});
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
