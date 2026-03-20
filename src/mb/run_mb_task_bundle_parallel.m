function task_results = run_mb_task_bundle_parallel(tasks, worker_fn, parallel_policy)
%RUN_MB_TASK_BUNDLE_PARALLEL Execute MB task bundles with optional outer parallelism.

if nargin < 1 || isempty(tasks)
    task_results = repmat(struct(), 0, 1);
    return;
end
if nargin < 2 || ~isa(worker_fn, 'function_handle')
    error('run_mb_task_bundle_parallel requires a worker_fn handle.');
end
if nargin < 3 || isempty(parallel_policy)
    parallel_policy = resolve_mb_parallel_policy(struct('parallel_policy', 'off'));
end

n_tasks = numel(tasks);
result_cells = cell(n_tasks, 1);
if ~logical(parallel_policy.outer_enabled) || n_tasks <= 1
    for idx = 1:n_tasks
        result_cells{idx, 1} = worker_fn(tasks(idx));
    end
else
    ensure_parallel_pool(char(parallel_policy.pool_profile), parallel_policy.max_workers_outer);
    parfor idx = 1:n_tasks
        result_cells{idx, 1} = worker_fn(tasks(idx));
    end
end

task_results = vertcat(result_cells{:});
end
