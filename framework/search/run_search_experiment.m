function result = run_search_experiment(spec)
%RUN_SEARCH_EXPERIMENT Minimal spec-driven unified search runner.
%
% Required:
%   spec.design_grid
%   or spec.design_grid_builder
%
% Optional:
%   spec.cfg_base
%   spec.cfg_overlay
%   spec.task_family
%   spec.task_family_builder
%   spec.evaluator_mode
%   spec.search_spec
%   spec.output_requests
%
% Output:
%   result.cfg
%   result.task_family
%   result.design_grid
%   result.search_result
%   result.grid_table
%   result.meta
%   result.outputs

if nargin < 1 || isempty(spec)
    error('run_search_experiment:MissingSpec', 'A spec struct is required.');
end

if ~isfield(spec, 'cfg_base') || isempty(spec.cfg_base)
    cfg_base = default_params();
else
    cfg_base = spec.cfg_base;
end

if ~isfield(spec, 'cfg_overlay') || isempty(spec.cfg_overlay)
    cfg_overlay = struct();
else
    cfg_overlay = spec.cfg_overlay;
end

cfg = local_merge_cfg(cfg_base, cfg_overlay);

design_grid = local_resolve_design_grid(spec, cfg);
task_family = local_resolve_task_family(spec, cfg);

if ~isfield(spec, 'evaluator_mode') || isempty(spec.evaluator_mode)
    evaluator_mode = 'opend';
else
    evaluator_mode = spec.evaluator_mode;
end

if ~isfield(spec, 'search_spec') || isempty(spec.search_spec)
    search_spec = struct();
else
    search_spec = spec.search_spec;
end

search_result = run_design_grid_search(design_grid, task_family, evaluator_mode, cfg, search_spec);

if ~isfield(spec, 'output_requests') || isempty(spec.output_requests)
    outputs = struct();
    outputs.truth_table = search_result.grid_table;
else
    outputs = run_search_outputs(search_result.grid_table, spec.output_requests);
end

result = struct();
result.cfg = cfg;
result.task_family = task_family;
result.design_grid = design_grid;
result.search_result = search_result;
result.grid_table = search_result.grid_table;
result.meta = search_result.meta;
result.outputs = outputs;
end

function cfg_out = local_merge_cfg(cfg_base, cfg_overlay)
cfg_out = cfg_base;
overlay_fields = fieldnames(cfg_overlay);
for i = 1:numel(overlay_fields)
    f = overlay_fields{i};
    cfg_out.(f) = cfg_overlay.(f);
end
end

function design_grid = local_resolve_design_grid(spec, cfg)
if isfield(spec, 'design_grid') && ~isempty(spec.design_grid)
    design_grid = spec.design_grid;
    return;
end

if isfield(spec, 'design_grid_builder') && ~isempty(spec.design_grid_builder)
    builder = spec.design_grid_builder;

    if isa(builder, 'function_handle')
        design_grid = builder(cfg, spec);
        return;
    elseif isstruct(builder)
        if isfield(builder, 'fn') && isa(builder.fn, 'function_handle')
            if isfield(builder, 'args')
                design_grid = builder.fn(cfg, spec, builder.args);
            else
                design_grid = builder.fn(cfg, spec);
            end
            return;
        end
    end

    error('run_search_experiment:InvalidDesignGridBuilder', ...
        'spec.design_grid_builder must be a function handle or a struct with field fn.');
end

error('run_search_experiment:MissingDesignGrid', ...
    'Either spec.design_grid or spec.design_grid_builder is required.');
end

function task_family = local_resolve_task_family(spec, cfg)
if isfield(spec, 'task_family') && ~isempty(spec.task_family)
    task_family = spec.task_family;
    return;
end

if isfield(spec, 'task_family_builder') && ~isempty(spec.task_family_builder)
    builder = spec.task_family_builder;

    if isa(builder, 'function_handle')
        task_family = builder(cfg, spec);
        return;
    elseif isstruct(builder)
        if isfield(builder, 'fn') && isa(builder.fn, 'function_handle')
            if isfield(builder, 'args')
                task_family = builder.fn(cfg, spec, builder.args);
            else
                task_family = builder.fn(cfg, spec);
            end
            return;
        end
    end

    error('run_search_experiment:InvalidTaskFamilyBuilder', ...
        'spec.task_family_builder must be a function handle or a struct with field fn.');
end

task_family = task_family_service(cfg);
end
