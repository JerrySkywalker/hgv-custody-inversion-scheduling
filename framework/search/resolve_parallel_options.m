function opts = resolve_parallel_options(search_spec)
if nargin < 1 || isempty(search_spec)
    search_spec = struct();
end

opts = struct();
opts.use_parallel = false;
opts.pool_profile = 'local';
opts.num_workers = [];
opts.show_progress = true;
opts.min_parallel_rows = 20;

if isfield(search_spec, 'use_parallel')
    opts.use_parallel = logical(search_spec.use_parallel);
end
if isfield(search_spec, 'pool_profile')
    opts.pool_profile = search_spec.pool_profile;
end
if isfield(search_spec, 'num_workers')
    opts.num_workers = search_spec.num_workers;
end
if isfield(search_spec, 'show_progress')
    opts.show_progress = logical(search_spec.show_progress);
end
if isfield(search_spec, 'min_parallel_rows') && ~isempty(search_spec.min_parallel_rows)
    opts.min_parallel_rows = search_spec.min_parallel_rows;
end
end
