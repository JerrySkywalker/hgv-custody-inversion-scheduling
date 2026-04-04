function info = load_latest_stage05_cache(cfg)
%LOAD_LATEST_STAGE05_CACHE  Locate and load the latest Stage05 cache.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end

patterns = cfg.ch5r.bootstrap.stage05_patterns;
file = local_find_latest_file(cfg, patterns);

info = struct();
info.stage_name = 'stage05';
info.found = ~isempty(file);
info.file = file;
info.load_ok = false;
info.data = struct();
info.feasible_table = table();
info.source = 'defaults';

if isempty(file)
    return;
end

S = load(file);
info.data = S;
info.load_ok = true;
info.source = 'cache';
info.feasible_table = local_extract_feasible_table(S);
end

function file = local_find_latest_file(cfg, patterns)
file = '';
listing = struct([]);

if exist('find_stage_cache_files', 'file') == 2
    for i = 1:numel(patterns)
        d = find_stage_cache_files(cfg, patterns{i});
        if ~isempty(d)
            d = d(contains(string({d.folder}), ['stage05']));
            listing = [listing; d(:)]; %#ok<AGROW>
        end
    end
else
    search_root = cfg.paths.stage_outputs;
    for i = 1:numel(patterns)
        d = dir(fullfile(search_root, 'stage05', 'cache', patterns{i}));
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

function T = local_extract_feasible_table(S)
T = table();

tbl = local_find_table_recursive(S, 'feasible_grid');
if ~isempty(tbl)
    T = tbl;
    return;
end

tbl = local_find_table_recursive(S, 'best_feasible');
if ~isempty(tbl)
    T = tbl;
    return;
end

tbl = local_find_table_recursive(S, 'feasible_table');
if ~isempty(tbl)
    T = tbl;
    return;
end
end

function T = local_find_table_recursive(x, field_name)
T = table();
if isstruct(x)
    fns = fieldnames(x);
    for i = 1:numel(fns)
        fn = fns{i};
        if strcmpi(fn, field_name)
            val = x.(fn);
            if istable(val)
                T = val;
                return;
            end
        end
        T = local_find_table_recursive(x.(fn), field_name);
        if ~isempty(T)
            return;
        end
    end
end
end
