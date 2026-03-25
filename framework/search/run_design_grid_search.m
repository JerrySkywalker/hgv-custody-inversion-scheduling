function search_result = run_design_grid_search(design_grid, task_family, evaluator_mode, engine_cfg, search_spec)
%RUN_DESIGN_GRID_SEARCH Unified design-grid search entry point.
% Inputs:
%   design_grid     : struct array or table of design rows
%   task_family     : struct with .trajs_in or a trajs_in struct array
%   evaluator_mode  : 'opend' or 'closedd'
%   engine_cfg      : engine configuration tree; defaults to default_params()
%   search_spec     : optional struct controlling cache/meta behavior
%
% Output:
%   search_result   : struct with grid_table, meta, manifest_paths, cache_path

if nargin < 4 || isempty(engine_cfg)
    engine_cfg = default_params();
end
if nargin < 5 || isempty(search_spec)
    search_spec = struct();
end

trajs_in = local_get_trajs_in(task_family);
engine_mode = lower(char(string(evaluator_mode)));

if ~isfield(search_spec, 'gamma_eff_scalar') || isempty(search_spec.gamma_eff_scalar)
    search_spec.gamma_eff_scalar = 1.0;
end
if ~isfield(search_spec, 'run_tag') || isempty(search_spec.run_tag)
    search_spec.run_tag = make_run_tag(engine_mode);
end
if ~isfield(search_spec, 'source_profile') || isempty(search_spec.source_profile)
    search_spec.source_profile = struct();
end
if ~isfield(search_spec, 'source_kind') || isempty(search_spec.source_kind)
    search_spec.source_kind = 'design_grid_search';
end
if ~isfield(search_spec, 'cache_output_dir') || isempty(search_spec.cache_output_dir)
    search_spec.cache_output_dir = fullfile('outputs', 'framework', 'cache', 'truth');
end
if ~isfield(search_spec, 'save_cache') || isempty(search_spec.save_cache)
    search_spec.save_cache = true;
end

logging_opts = resolve_search_logging_options(search_spec);
logger = make_logger(logging_opts);

parallel_opts = resolve_parallel_options(search_spec);

rows = local_extract_design_rows(design_grid);
n = numel(rows);

if parallel_opts.use_parallel && n < parallel_opts.min_parallel_rows
    log_message(logger, 'INFO', 'Parallel requested but disabled because n_rows=%d < min_parallel_rows=%d', n, parallel_opts.min_parallel_rows);
    parallel_opts.use_parallel = false;
end

log_message(logger, 'INFO', 'Starting design-grid search: mode=%s, n_rows=%d, gamma=%.10g, parallel=%d', ...
    engine_mode, n, search_spec.gamma_eff_scalar, parallel_opts.use_parallel);

if parallel_opts.use_parallel
    result_rows = run_design_grid_search_parallel(rows, trajs_in, engine_mode, engine_cfg, search_spec, logger, parallel_opts);
else
    result_cells = cell(n, 1);

    for k = 1:n
        row = rows(k);

        if logging_opts.show_progress && (mod(k, logging_opts.progress_every) == 0 || k == 1 || k == n)
            if isfield(row, 'design_id')
                rid = string(row.design_id);
            else
                rid = sprintf('row_%d', k);
            end
            log_message(logger, 'INFO', '[%d/%d] evaluating %s', k, n, rid);
        end

        switch engine_mode
            case 'opend'
                eval_out = evaluate_design_point_opend(row, trajs_in, search_spec.gamma_eff_scalar, engine_cfg);
            case 'closedd'
                eval_out = evaluate_design_point_closedd(row, trajs_in, search_spec.gamma_eff_scalar, engine_cfg);
            otherwise
                error('run_design_grid_search:UnsupportedMode', ...
                    'Unsupported evaluator mode: %s', engine_mode);
        end

        result_cells{k} = local_pack_result_row(row, eval_out, engine_mode, search_spec);
    end

    result_rows = vertcat(result_cells{:});
end

grid_table = struct2table(result_rows);
grid_table = local_standardize_grid_table(grid_table, engine_mode, search_spec);

meta = local_build_meta(design_grid, task_family, engine_mode, search_spec);
manifest_paths = struct();
cache_path = '';

if search_spec.save_cache
    cache_key = make_cache_key(meta.source_kind, meta.engine_mode, meta.run_tag);
    cache_info = save_truth_table_cache(grid_table, meta, struct( ...
        'output_dir', search_spec.cache_output_dir, ...
        'cache_key', cache_key));
    manifest_paths = rmfield(cache_info, {'cache_path', 'latest_path', 'cache_key'});
    cache_path = cache_info.cache_path;
    log_message(logger, 'INFO', 'Saved truth-table cache: %s', cache_path);
end

search_result = struct();
search_result.grid_table = grid_table;
search_result.meta = meta;
search_result.manifest_paths = manifest_paths;
search_result.cache_path = cache_path;

log_message(logger, 'INFO', 'Completed design-grid search: mode=%s, n_rows=%d', engine_mode, n);
end

function trajs_in = local_get_trajs_in(task_family)
if isstruct(task_family) && isfield(task_family, 'trajs_in')
    trajs_in = task_family.trajs_in;
else
    trajs_in = task_family;
end
end

function rows = local_extract_design_rows(design_grid)
if istable(design_grid)
    rows = table2struct(design_grid);
elseif isstruct(design_grid)
    if isfield(design_grid, 'rows')
        rows = design_grid.rows;
    elseif isfield(design_grid, 'design_table')
        rows = design_grid.design_table;
    else
        rows = design_grid;
    end
else
    error('run_design_grid_search:UnsupportedDesignGridType', ...
        'Unsupported design_grid type: %s', class(design_grid));
end

if istable(rows)
    rows = table2struct(rows);
end
end

function packed = local_pack_result_row(row, eval_out, engine_mode, search_spec)
packed = row;

eval_fields = fieldnames(eval_out);
for i = 1:numel(eval_fields)
    f = eval_fields{i};
    packed.(f) = eval_out.(f);
end

if ~isfield(packed, 'gamma_eff_scalar')
    packed.gamma_eff_scalar = search_spec.gamma_eff_scalar;
end
if ~isfield(packed, 'engine_mode')
    packed.engine_mode = string(engine_mode);
end
if ~isfield(packed, 'source_kind')
    packed.source_kind = string(search_spec.source_kind);
end
end

function meta = local_build_meta(design_grid, task_family, engine_mode, search_spec)
meta = struct();
meta.engine_mode = engine_mode;
meta.grid_spec = design_grid;
meta.task_family_spec = summarize_task_family(local_wrap_task_family(task_family));
meta.threshold_spec = struct('gamma_eff_scalar', search_spec.gamma_eff_scalar);
meta.source_profile = search_spec.source_profile;
meta.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
meta.run_tag = char(string(search_spec.run_tag));
meta.code_version = '';
meta.source_kind = char(string(search_spec.source_kind));
end

function task_family = local_wrap_task_family(task_family_in)
if isstruct(task_family_in) && isfield(task_family_in, 'trajs_in')
    task_family = task_family_in;
elseif isstruct(task_family_in)
    task_family = struct('name', 'anonymous', 'trajs_in', task_family_in);
else
    task_family = struct('name', 'anonymous', 'trajs_in', struct('case', {}, 'traj', {}));
end
end

function grid_table = local_standardize_grid_table(grid_table, engine_mode, search_spec)
if ~istable(grid_table)
    return;
end

vars = grid_table.Properties.VariableNames;
if ismember('feasible_flag', vars) && ~ismember('is_feasible', vars)
    grid_table.is_feasible = logical(grid_table.feasible_flag);
end
if ~ismember('gamma_eff_scalar', vars)
    grid_table.gamma_eff_scalar = repmat(search_spec.gamma_eff_scalar, height(grid_table), 1);
end
if ~ismember('engine_mode', vars)
    grid_table.engine_mode = repmat(string(engine_mode), height(grid_table), 1);
end
if ~ismember('source_kind', vars)
    grid_table.source_kind = repmat(string(search_spec.source_kind), height(grid_table), 1);
end
end
