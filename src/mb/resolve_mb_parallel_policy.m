function policy = resolve_mb_parallel_policy(cfg_or_meta, overrides)
%RESOLVE_MB_PARALLEL_POLICY Resolve MB semantic-compare parallel policy.

if nargin < 1 || isempty(cfg_or_meta)
    meta = struct();
    runtime_parallel = struct();
elseif isstruct(cfg_or_meta) && isfield(cfg_or_meta, 'milestones') ...
        && isfield(cfg_or_meta.milestones, 'MB_semantic_compare')
    meta = cfg_or_meta.milestones.MB_semantic_compare;
    runtime_parallel = local_getfield_or(local_getfield_or(cfg_or_meta, 'runtime', struct()), 'parallel', struct());
else
    meta = cfg_or_meta;
    runtime_parallel = local_getfield_or(local_getfield_or(cfg_or_meta, 'runtime', struct()), 'parallel', struct());
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

requested_name = lower(char(string(local_getfield_or(overrides, 'parallel_policy', ...
    local_getfield_or(meta, 'parallel_policy', "")))));
runtime_scope = lower(char(string(local_getfield_or(overrides, 'parallel_scope', ...
    local_getfield_or(runtime_parallel, 'scope', "none")))));
runtime_enabled = logical(local_getfield_or(overrides, 'parallel_enable', ...
    local_getfield_or(runtime_parallel, 'enable', false)));

if strlength(string(requested_name)) == 0 || strcmpi(requested_name, 'off')
    if runtime_enabled || ~strcmpi(runtime_scope, 'none')
        name = local_map_runtime_scope_to_policy(runtime_scope);
    else
        name = 'off';
    end
else
    name = requested_name;
end

switch lower(name)
    case {'off', 'serial'}
        resolved_name = "off";
        resolved_scope = "none";
        description = "Serial task orchestration; preserve the existing evaluator-level parallel settings.";
        outer_enabled = false;
        inner_enabled = false;
    case {'task_bundle', 'outer_loop_only'}
        resolved_name = "task_bundle";
        resolved_scope = "outer_loop_only";
        description = "Parallelize semantic compare task bundles over height x sensor-group x semantic-mode.";
        outer_enabled = true;
        inner_enabled = false;
    case {'task_plus_partition', 'design_block_only'}
        resolved_name = "task_plus_partition";
        resolved_scope = "design_block_only";
        description = "Run task bundles serially and parallelize design partitions within each semantic evaluation.";
        outer_enabled = false;
        inner_enabled = true;
    otherwise
        resolved_name = "off";
        resolved_scope = "none";
        description = "Unknown policy token; falling back to serial task orchestration.";
        outer_enabled = false;
        inner_enabled = false;
end

policy = struct( ...
    'name', resolved_name, ...
    'scope', string(resolved_scope), ...
    'description', string(description), ...
    'outer_enabled', outer_enabled, ...
    'inner_enabled', inner_enabled, ...
    'allow_nested_parallel', logical(local_getfield_or(overrides, 'allow_nested_parallel', ...
        local_getfield_or(meta, 'allow_nested_parallel', false))), ...
    'max_workers_outer', max(1, local_getfield_or(overrides, 'max_workers_outer', ...
        local_getfield_or(meta, 'max_workers_outer', local_getfield_or(runtime_parallel, 'max_workers', 4)))), ...
    'max_workers_inner', max(1, local_getfield_or(overrides, 'max_workers_inner', ...
        local_getfield_or(meta, 'max_workers_inner', local_getfield_or(runtime_parallel, 'max_workers', 4)))), ...
    'pool_profile', string(local_getfield_or(overrides, 'parallel_pool_profile', ...
        local_getfield_or(meta, 'parallel_pool_profile', "local"))), ...
    'partition_strategy', string(local_getfield_or(overrides, 'partition_strategy', ...
        local_getfield_or(meta, 'parallel_partition_strategy', "inclination"))), ...
    'runtime_enabled', runtime_enabled, ...
    'runtime_scope', string(runtime_scope));
end

function name = local_map_runtime_scope_to_policy(scope_name)
switch lower(char(string(scope_name)))
    case {'outer_loop_only', 'task_bundle'}
        name = 'task_bundle';
    case {'design_block_only', 'task_plus_partition'}
        name = 'task_plus_partition';
    otherwise
        name = 'off';
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
