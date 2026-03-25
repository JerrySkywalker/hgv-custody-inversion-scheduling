function cache_key = make_cache_key(source_kind, engine_mode, run_tag)
%MAKE_CACHE_KEY Build a filesystem-safe cache key.
% Inputs:
%   source_kind : cache source kind, e.g. 'design_grid_search'
%   engine_mode : evaluator mode, e.g. 'opend' or 'closedd'
%   run_tag     : run tag or profile hint

if nargin < 1 || isempty(source_kind)
    source_kind = 'cache';
end
if nargin < 2 || isempty(engine_mode)
    engine_mode = 'generic';
end
if nargin < 3 || isempty(run_tag)
    run_tag = make_run_tag('run');
end

parts = {char(string(source_kind)), char(string(engine_mode)), char(string(run_tag))};
cache_key = strjoin(parts, '_');
cache_key = regexprep(cache_key, '[^A-Za-z0-9_\-]', '_');
cache_key = regexprep(cache_key, '_+', '_');
cache_key = regexprep(cache_key, '^_|_$', '');
end
