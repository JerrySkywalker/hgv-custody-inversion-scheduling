function info = load_latest_stage04_cache(cfg)
%LOAD_LATEST_STAGE04_CACHE  Locate and load the latest Stage04 cache.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end

patterns = cfg.ch5r.bootstrap.stage04_patterns;
file = local_find_latest_file(cfg, patterns);

info = struct();
info.stage_name = 'stage04';
info.found = ~isempty(file);
info.file = file;
info.load_ok = false;
info.data = struct();
info.gamma_req = max(cfg.stage04.gamma_floor, cfg.stage04.gamma_req_fixed);
info.source = 'defaults';

if isempty(file)
    return;
end

S = load(file);
info.data = S;
info.load_ok = true;
info.source = 'cache';

gamma_val = local_extract_gamma_req(S);
if ~isempty(gamma_val) && isfinite(gamma_val)
    info.gamma_req = max(gamma_val, cfg.stage04.gamma_floor);
end
end

function file = local_find_latest_file(cfg, patterns)
file = '';
listing = struct([]);

if exist('find_stage_cache_files', 'file') == 2
    for i = 1:numel(patterns)
        d = find_stage_cache_files(cfg, patterns{i});
        if ~isempty(d)
            listing = [listing; d(:)]; %#ok<AGROW>
        end
    end
else
    search_root = cfg.paths.stage_outputs;
    for i = 1:numel(patterns)
        d = dir(fullfile(search_root, 'stage04', 'cache', patterns{i}));
        if ~isempty(d)
            listing = [listing; d(:)]; %#ok<AGROW>
        end
    end
end

if isempty(listing)
    return;
end

[~, idx] = max([listing.datenum]);
file = fullfile(listing(idx).folder, listing(idx).name);
end

function gamma_val = local_extract_gamma_req(S)
gamma_val = [];

candidates = { ...
    'gamma_req', ...
    'gamma_req_fixed', ...
    'gamma_floor'};

for i = 1:numel(candidates)
    v = local_find_scalar_recursive(S, candidates{i});
    if ~isempty(v)
        gamma_val = v;
        return;
    end
end
end

function v = local_find_scalar_recursive(x, field_name)
v = [];
if isstruct(x)
    fns = fieldnames(x);
    for i = 1:numel(fns)
        fn = fns{i};
        if strcmpi(fn, field_name)
            val = x.(fn);
            if isnumeric(val) && isscalar(val) && isfinite(val)
                v = double(val);
                return;
            end
        end
        v = local_find_scalar_recursive(x.(fn), field_name);
        if ~isempty(v)
            return;
        end
    end
end
end
