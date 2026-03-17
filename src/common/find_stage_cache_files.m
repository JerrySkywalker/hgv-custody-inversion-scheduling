function listing = find_stage_cache_files(cfg_or_cache_dir, pattern)
%FIND_STAGE_CACHE_FILES Find cache files across stage-scoped cache folders.

search_root = local_resolve_stage_root(cfg_or_cache_dir);
listing = struct([]);
if isempty(search_root) || ~exist(search_root, 'dir')
    return;
end

stage_dirs = dir(search_root);
stage_dirs = stage_dirs([stage_dirs.isdir]);
stage_dirs = stage_dirs(~ismember({stage_dirs.name}, {'.', '..'}));

for k = 1:numel(stage_dirs)
    cache_dir = fullfile(stage_dirs(k).folder, stage_dirs(k).name, 'cache');
    if ~exist(cache_dir, 'dir')
        continue;
    end
    matches = dir(fullfile(cache_dir, pattern));
    if isempty(matches)
        continue;
    end
    if isempty(listing)
        listing = matches;
    else
        listing = [listing; matches]; %#ok<AGROW>
    end
end
end

function search_root = local_resolve_stage_root(cfg_or_cache_dir)
search_root = '';
if isstruct(cfg_or_cache_dir)
    if isfield(cfg_or_cache_dir, 'paths') && isfield(cfg_or_cache_dir.paths, 'stage_outputs')
        search_root = cfg_or_cache_dir.paths.stage_outputs;
    elseif isfield(cfg_or_cache_dir, 'stage_outputs')
        search_root = cfg_or_cache_dir.stage_outputs;
    end
    return;
end

cache_dir = char(string(cfg_or_cache_dir));
if isempty(cache_dir)
    return;
end

[maybe_stage_root, leaf_name] = fileparts(cache_dir);
if strcmpi(leaf_name, 'cache')
    search_root = fileparts(maybe_stage_root);
elseif exist(fullfile(cache_dir, 'stage00'), 'dir') || exist(fullfile(cache_dir, 'stage01'), 'dir')
    search_root = cache_dir;
elseif exist(cache_dir, 'dir')
    search_root = cache_dir;
end
end
