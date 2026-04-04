function info = load_latest_stage05_cache(cfg)
%LOAD_LATEST_STAGE05_CACHE  Locate and load the latest Stage05 cache.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end

patterns = cfg.ch5r.bootstrap.stage05_patterns;
[file, match_pattern] = local_find_latest_file(cfg, patterns);

info = struct();
info.stage_name = 'stage05';
info.found = ~isempty(file);
info.file = file;
info.match_pattern = match_pattern;
info.load_ok = false;
info.data = struct();
info.feasible_table = table();
info.source = 'defaults';
info.cache_kind = 'none';

if isempty(file)
    return;
end

S = load(file);
info.data = S;
info.load_ok = true;
info.source = 'cache';
info.feasible_table = local_extract_feasible_table(S);
info.cache_kind = local_infer_cache_kind(file, match_pattern);
end

function [file, match_pattern] = local_find_latest_file(cfg, patterns)
file = '';
match_pattern = '';
best_priority = inf;
best_datenum = -inf;

listing = [];

for i = 1:numel(patterns)
    pattern = patterns{i};
    d = local_find_candidates(cfg, pattern);
    if isempty(d)
        continue;
    end
    for k = 1:numel(d)
        entry = d(k);
        this_priority = i;
        this_datenum = entry.datenum;
        if this_priority < best_priority || ...
           (this_priority == best_priority && this_datenum > best_datenum)
            best_priority = this_priority;
            best_datenum = this_datenum;
            file = fullfile(entry.folder, entry.name);
            match_pattern = pattern;
        end
    end
    listing = [listing; d(:)]; %#ok<AGROW>
end
end

function d = local_find_candidates(cfg, pattern)
d = struct([]);

if exist('find_stage_cache_files', 'file') == 2
    tmp = find_stage_cache_files(cfg, pattern);
    if ~isempty(tmp)
        mask = contains(string({tmp.folder}), 'stage05');
        d = tmp(mask);
    end
else
    search_root = cfg.paths.stage_outputs;
    tmp = dir(fullfile(search_root, 'stage05', 'cache', pattern));
    if ~isempty(tmp)
        d = tmp;
    end
end
end

function kind = local_infer_cache_kind(file, match_pattern)
txt = lower(string(file) + " " + string(match_pattern));
if contains(txt, "search")
    kind = 'search';
elseif contains(txt, "plot")
    kind = 'plot';
else
    kind = 'generic';
end
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

tbl = local_find_table_recursive(S, 'results_table');
if ~isempty(tbl)
    T = tbl;
    return;
end

tbl = local_find_table_recursive(S, 'summary_table');
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
