function cache_payload = load_truth_table_cache(cache_ref, options)
%LOAD_TRUTH_TABLE_CACHE Load a truth-table cache payload.
% Inputs:
%   cache_ref : full MAT path or cache key
%   options   : optional struct with output_dir

if nargin < 2 || isempty(options)
    options = struct();
end
if ~isfield(options, 'output_dir') || isempty(options.output_dir)
    options.output_dir = fullfile('outputs', 'framework', 'cache', 'truth');
end

if exist(cache_ref, 'file') == 2
    cache_path = cache_ref;
else
    cache_path = resolve_latest_cache(options.output_dir, cache_ref);
end

tmp = load(cache_path, 'payload');
assert(isfield(tmp, 'payload'), 'load_truth_table_cache:InvalidCache', ...
    'Cache file missing payload: %s', cache_path);
assert(isfield(tmp.payload, 'grid_table') && isfield(tmp.payload, 'meta'), ...
    'load_truth_table_cache:InvalidPayload', ...
    'Truth cache missing grid_table or meta: %s', cache_path);

cache_payload = tmp.payload;
cache_payload.cache_path = cache_path;
end
