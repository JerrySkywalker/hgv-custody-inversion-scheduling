function plan = resolve_mb_parallel_plan(cfg_or_meta, overrides)
%RESOLVE_MB_PARALLEL_PLAN Resolve a user-facing MB runtime parallel plan.

if nargin < 1 || isempty(cfg_or_meta)
    cfg_or_meta = struct();
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

policy = resolve_mb_parallel_policy(cfg_or_meta, overrides);
runtime_parallel = local_resolve_runtime_parallel(cfg_or_meta, overrides);

plan = struct( ...
    'enabled', logical(local_getfield_or(runtime_parallel, 'enable', false) || policy.outer_enabled || policy.inner_enabled), ...
    'scope', string(local_getfield_or(runtime_parallel, 'scope', local_getfield_or(policy, 'scope', "none"))), ...
    'mode', string(local_getfield_or(runtime_parallel, 'mode', local_scope_to_mode(local_getfield_or(runtime_parallel, 'scope', local_getfield_or(policy, 'scope', "none"))))), ...
    'max_workers', max(1, local_getfield_or(runtime_parallel, 'max_workers', max(local_getfield_or(policy, 'max_workers_outer', 1), local_getfield_or(policy, 'max_workers_inner', 1)))), ...
    'policy_name', string(local_getfield_or(policy, 'name', "off")), ...
    'policy_scope', string(local_getfield_or(policy, 'scope', "none")), ...
    'outer_enabled', logical(local_getfield_or(policy, 'outer_enabled', false)), ...
    'inner_enabled', logical(local_getfield_or(policy, 'inner_enabled', false)), ...
    'description', string(local_getfield_or(policy, 'description', "")));
end

function runtime_parallel = local_resolve_runtime_parallel(cfg_or_meta, overrides)
runtime_parallel = struct();
if isstruct(cfg_or_meta)
    runtime_parallel = local_getfield_or(local_getfield_or(cfg_or_meta, 'runtime', struct()), 'parallel', struct());
    direct_parallel = local_getfield_or(cfg_or_meta, 'parallel', struct());
    runtime_parallel = milestone_common_merge_structs(runtime_parallel, direct_parallel);
end
if isstruct(overrides) && ~isempty(fieldnames(overrides))
    runtime_parallel = milestone_common_merge_structs(runtime_parallel, overrides);
end
end

function mode_name = local_scope_to_mode(scope_name)
switch lower(char(string(scope_name)))
    case {'outer_loop_only', 'task_bundle'}
        mode_name = "grid";
    case {'design_block_only', 'task_plus_partition'}
        mode_name = "design_block";
    otherwise
        mode_name = "serial";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
