function result = run_search_experiment(spec)
%RUN_SEARCH_EXPERIMENT Minimal spec-driven unified search runner.
%
% Required:
%   spec.design_grid
%
% Optional:
%   spec.cfg_base
%   spec.cfg_overlay
%   spec.task_family
%   spec.evaluator_mode
%   spec.search_spec
%
% Output:
%   result.cfg
%   result.task_family
%   result.search_result
%   result.grid_table
%   result.meta

if nargin < 1 || isempty(spec)
    error('run_search_experiment:MissingSpec', 'A spec struct is required.');
end

if ~isfield(spec, 'design_grid') || isempty(spec.design_grid)
    error('run_search_experiment:MissingDesignGrid', 'spec.design_grid is required.');
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

if ~isfield(spec, 'task_family') || isempty(spec.task_family)
    task_family = task_family_service(cfg);
else
    task_family = spec.task_family;
end

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

search_result = run_design_grid_search(spec.design_grid, task_family, evaluator_mode, cfg, search_spec);

result = struct();
result.cfg = cfg;
result.task_family = task_family;
result.search_result = search_result;
result.grid_table = search_result.grid_table;
result.meta = search_result.meta;
end

function cfg_out = local_merge_cfg(cfg_base, cfg_overlay)
cfg_out = cfg_base;
overlay_fields = fieldnames(cfg_overlay);
for i = 1:numel(overlay_fields)
    f = overlay_fields{i};
    cfg_out.(f) = cfg_overlay.(f);
end
end
