function partition_outputs = run_mb_design_partition_parallel(partitions, worker_fn, parallel_policy)
%RUN_MB_DESIGN_PARTITION_PARALLEL Execute MB design partitions with optional parfor.

if nargin < 1 || isempty(partitions)
    partition_outputs = {};
    return;
end
if nargin < 2 || ~isa(worker_fn, 'function_handle')
    error('run_mb_design_partition_parallel requires a worker_fn handle.');
end
if nargin < 3 || isempty(parallel_policy)
    parallel_policy = resolve_mb_parallel_policy(struct('parallel_policy', 'off'));
end

n_parts = numel(partitions);
partition_outputs = cell(n_parts, 1);
if ~logical(parallel_policy.inner_enabled) || n_parts <= 1
    for idx = 1:n_parts
        partition_outputs{idx, 1} = worker_fn(partitions{idx});
    end
else
    ensure_parallel_pool(char(parallel_policy.pool_profile), parallel_policy.max_workers_inner);
    parfor idx = 1:n_parts
        partition_outputs{idx, 1} = worker_fn(partitions{idx});
    end
end
end
