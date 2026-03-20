function label = format_mb_search_domain_label(search_domain_in, detail_level)
%FORMAT_MB_SEARCH_DOMAIN_LABEL Human-readable MB search-domain label.

if nargin < 1 || isempty(search_domain_in)
    search_domain_in = struct();
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

if ~isstruct(search_domain_in)
    error('format_mb_search_domain_label expects a search-domain struct.');
end
search_domain = search_domain_in;

parts = strings(0, 1);
ns_initial = reshape(local_getfield_or(search_domain, 'Ns_initial_range', []), 1, []);
if numel(ns_initial) >= 3 && all(isfinite(ns_initial(1:3)))
    parts(end + 1, 1) = string(sprintf('Ns0[%g:%g:%g]', ns_initial(1), ns_initial(2), ns_initial(3)));
else
    ns_min = local_getfield_or(search_domain, 'ns_search_min', NaN);
    ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
    ns_step = local_getfield_or(search_domain, 'ns_search_step', NaN);
    if isfinite(ns_min) && isfinite(ns_max)
        if isfinite(ns_step)
            parts(end + 1, 1) = string(sprintf('Ns[%g:%g:%g]', ns_min, ns_step, ns_max));
        else
            parts(end + 1, 1) = string(sprintf('Ns[%g,%g]', ns_min, ns_max));
        end
    end
end

blocks = local_getfield_or(search_domain, 'Ns_expand_blocks', []);
if isstruct(blocks) && ~isempty(blocks)
    parts(end + 1, 1) = string(sprintf('blocks=%d', numel(blocks)));
end

hard_max = local_getfield_or(search_domain, 'Ns_hard_max', NaN);
if isfinite(hard_max)
    parts(end + 1, 1) = string(sprintf('hardMax=%g', hard_max));
end

P_grid = reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []);
T_grid = reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []);
if ~isempty(P_grid)
    parts(end + 1, 1) = "P=" + local_format_grid(P_grid);
end
if ~isempty(T_grid)
    parts(end + 1, 1) = "T=" + local_format_grid(T_grid);
end
if logical(local_getfield_or(search_domain, 'strict_stage05_reference', false))
    parts(end + 1, 1) = "strict_stage05_lock";
end
if logical(local_getfield_or(search_domain, 'allow_auto_expand_upper', false))
    parts(end + 1, 1) = "expand=on";
else
    parts(end + 1, 1) = "expand=off";
end
solve_domain_mode = string(local_getfield_or(search_domain, 'solve_domain_mode', ""));
if strlength(solve_domain_mode) > 0
    parts(end + 1, 1) = "solve=" + solve_domain_mode;
end

if strcmpi(char(string(detail_level)), 'detailed')
    heights = reshape(local_getfield_or(search_domain, 'height_grid_km', []), 1, []);
    inclinations = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', []), 1, []);
    if ~isempty(heights)
        parts(end + 1, 1) = "h=" + local_format_grid(heights);
    end
    if ~isempty(inclinations)
        parts(end + 1, 1) = "i=" + local_format_grid(inclinations);
    end
    policy_name = string(local_getfield_or(search_domain, 'policy_name', ""));
    if strlength(policy_name) > 0
        parts(end + 1, 1) = "policy=" + policy_name;
    end
    expand_strategy = string(local_getfield_or(search_domain, 'expand_strategy', ""));
    if strlength(expand_strategy) > 0
        parts(end + 1, 1) = "strategy=" + expand_strategy;
    end
    if isstruct(blocks) && ~isempty(blocks)
        parts(end + 1, 1) = "blockRanges=" + local_format_expand_blocks(blocks);
    end
end

if isempty(parts)
    label = "search-domain unavailable";
else
    label = strjoin(cellstr(parts), ', ');
end
end

function txt = local_format_grid(values)
values = reshape(values, 1, []);
txt = "{" + strjoin(cellstr(string(values)), ',') + "}";
end

function txt = local_format_expand_blocks(blocks)
labels = strings(1, numel(blocks));
for idx = 1:numel(blocks)
    block = blocks(idx);
    labels(idx) = string(sprintf('%s[%g:%g:%g]', ...
        char(string(local_getfield_or(block, 'name', "block" + idx))), ...
        local_getfield_or(block, 'ns_min', NaN), ...
        local_getfield_or(block, 'ns_step', NaN), ...
        local_getfield_or(block, 'ns_max', NaN)));
end
txt = "{" + strjoin(cellstr(labels), '; ') + "}";
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
