function cache_payload = load_derived_table_cache(cache_ref, options)
%LOAD_DERIVED_TABLE_CACHE Load a derived-table cache payload.

if nargin < 2 || isempty(options)
    options = struct();
end
if ~isfield(options, 'output_dir') || isempty(options.output_dir)
    options.output_dir = fullfile('outputs', 'framework', 'cache', 'derived');
end

if exist(cache_ref, 'file') == 2
    cache_path = cache_ref;
else
    cache_path = resolve_latest_cache(options.output_dir, cache_ref);
end

tmp = load(cache_path, 'payload');
assert(isfield(tmp, 'payload'), 'load_derived_table_cache:InvalidCache', ...
    'Cache file missing payload: %s', cache_path);

cache_payload = tmp.payload;
cache_payload.cache_path = cache_path;
end
