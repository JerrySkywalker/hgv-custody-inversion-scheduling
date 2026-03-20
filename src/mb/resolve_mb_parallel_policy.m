function policy = resolve_mb_parallel_policy(cfg_or_meta, overrides)
%RESOLVE_MB_PARALLEL_POLICY Resolve MB semantic-compare parallel policy.

if nargin < 1 || isempty(cfg_or_meta)
    meta = struct();
elseif isstruct(cfg_or_meta) && isfield(cfg_or_meta, 'milestones') ...
        && isfield(cfg_or_meta.milestones, 'MB_semantic_compare')
    meta = cfg_or_meta.milestones.MB_semantic_compare;
else
    meta = cfg_or_meta;
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

name = lower(char(string(local_getfield_or(overrides, 'parallel_policy', ...
    local_getfield_or(meta, 'parallel_policy', "off")))));
switch name
    case {'off', 'serial'}
        resolved_name = "off";
        description = "Serial task orchestration; preserve the existing evaluator-level parallel settings.";
        outer_enabled = false;
        inner_enabled = false;
    case 'task_bundle'
        resolved_name = "task_bundle";
        description = "Parallelize semantic compare task bundles over height x sensor-group x semantic-mode.";
        outer_enabled = true;
        inner_enabled = false;
    case 'task_plus_partition'
        resolved_name = "task_plus_partition";
        description = "Run task bundles serially and parallelize design partitions within each semantic evaluation.";
        outer_enabled = false;
        inner_enabled = true;
    otherwise
        resolved_name = "off";
        description = "Unknown policy token; falling back to serial task orchestration.";
        outer_enabled = false;
        inner_enabled = false;
end

policy = struct( ...
    'name', resolved_name, ...
    'description', string(description), ...
    'outer_enabled', outer_enabled, ...
    'inner_enabled', inner_enabled, ...
    'allow_nested_parallel', logical(local_getfield_or(overrides, 'allow_nested_parallel', ...
        local_getfield_or(meta, 'allow_nested_parallel', false))), ...
    'max_workers_outer', max(1, local_getfield_or(overrides, 'max_workers_outer', ...
        local_getfield_or(meta, 'max_workers_outer', 4))), ...
    'max_workers_inner', max(1, local_getfield_or(overrides, 'max_workers_inner', ...
        local_getfield_or(meta, 'max_workers_inner', 4))), ...
    'pool_profile', string(local_getfield_or(overrides, 'parallel_pool_profile', ...
        local_getfield_or(meta, 'parallel_pool_profile', "local"))), ...
    'partition_strategy', string(local_getfield_or(overrides, 'partition_strategy', ...
        local_getfield_or(meta, 'parallel_partition_strategy', "inclination"))));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
