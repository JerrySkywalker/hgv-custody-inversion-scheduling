function cache_file = find_latest_stage_cache(cfg_or_cache_dir, pattern, allow_empty)
%FIND_LATEST_STAGE_CACHE Find the newest cache file across stage caches.

if nargin < 3
    allow_empty = false;
end

listing = find_stage_cache_files(cfg_or_cache_dir, pattern);
if isempty(listing)
    if allow_empty
        cache_file = '';
        return;
    end
    error('No cache matched pattern: %s', pattern);
end

[~, idx] = max([listing.datenum]);
cache_file = fullfile(listing(idx).folder, listing(idx).name);
end
