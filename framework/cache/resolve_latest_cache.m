function cache_path = resolve_latest_cache(cache_dir, cache_key)
%RESOLVE_LATEST_CACHE Resolve the latest cache MAT path for a cache key.

if nargin < 2
    error('resolve_latest_cache requires cache_dir and cache_key.');
end

latest_path = fullfile(cache_dir, sprintf('%s_latest.mat', cache_key));
if exist(latest_path, 'file') == 2
    cache_path = latest_path;
    return;
end

d = dir(fullfile(cache_dir, sprintf('%s_*.mat', cache_key)));
if isempty(d)
    error('resolve_latest_cache:NotFound', ...
        'No cache found for key %s in %s.', cache_key, cache_dir);
end

[~, idx] = max([d.datenum]);
cache_path = fullfile(d(idx).folder, d(idx).name);
end
