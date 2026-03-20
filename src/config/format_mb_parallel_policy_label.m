function label = format_mb_parallel_policy_label(policy_in, detail_level)
%FORMAT_MB_PARALLEL_POLICY_LABEL Human-readable MB parallel policy summary.

if nargin < 1 || isempty(policy_in)
    policy_in = struct('parallel_policy', 'off');
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

policy = resolve_mb_parallel_policy(policy_in);
switch char(policy.name)
    case 'off'
        base = "off (serial)";
    case 'task_bundle'
        base = "task_bundle (outer bundles)";
    case 'task_plus_partition'
        base = "task_plus_partition (inner partitions)";
    otherwise
        base = string(policy.name);
end

if strcmpi(char(string(detail_level)), 'detailed')
    parts = [
        base
        "outer=" + local_onoff(policy.outer_enabled)
        "inner=" + local_onoff(policy.inner_enabled)
        "pool=" + string(policy.pool_profile)
        "workers_outer=" + string(policy.max_workers_outer)
        "workers_inner=" + string(policy.max_workers_inner)
        "nested=" + local_onoff(policy.allow_nested_parallel)
        "partition=" + string(policy.partition_strategy)];
    label = strjoin(cellstr(parts), ', ');
else
    label = sprintf('%s, pool=%s', char(base), char(string(policy.pool_profile)));
end
end

function txt = local_onoff(flag)
if logical(flag)
    txt = "on";
else
    txt = "off";
end
end
