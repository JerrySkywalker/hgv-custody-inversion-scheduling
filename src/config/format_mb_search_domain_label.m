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
ns_min = local_getfield_or(search_domain, 'ns_search_min', NaN);
ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
ns_step = local_getfield_or(search_domain, 'ns_search_step', NaN);
if isfinite(ns_min) && isfinite(ns_max)
    if isfinite(ns_step)
        parts(end + 1, 1) = string(sprintf('Ns[%g:%g:%g]', ns_min, ns_step, ns_max)); %#ok<AGROW>
    else
        parts(end + 1, 1) = string(sprintf('Ns[%g,%g]', ns_min, ns_max)); %#ok<AGROW>
    end
end

P_grid = reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []);
T_grid = reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []);
if ~isempty(P_grid)
    parts(end + 1, 1) = "P=" + local_format_grid(P_grid); %#ok<AGROW>
end
if ~isempty(T_grid)
    parts(end + 1, 1) = "T=" + local_format_grid(T_grid); %#ok<AGROW>
end
if logical(local_getfield_or(search_domain, 'strict_stage05_reference', false))
    parts(end + 1, 1) = "strict_stage05_lock"; %#ok<AGROW>
end
if logical(local_getfield_or(search_domain, 'allow_auto_expand_upper', false))
    parts(end + 1, 1) = "expand=on"; %#ok<AGROW>
else
    parts(end + 1, 1) = "expand=off"; %#ok<AGROW>
end

if strcmpi(char(string(detail_level)), 'detailed')
    heights = reshape(local_getfield_or(search_domain, 'height_grid_km', []), 1, []);
    inclinations = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', []), 1, []);
    if ~isempty(heights)
        parts(end + 1, 1) = "h=" + local_format_grid(heights); %#ok<AGROW>
    end
    if ~isempty(inclinations)
        parts(end + 1, 1) = "i=" + local_format_grid(inclinations); %#ok<AGROW>
    end
    policy_name = string(local_getfield_or(search_domain, 'policy_name', ""));
    if strlength(policy_name) > 0
        parts(end + 1, 1) = "policy=" + policy_name; %#ok<AGROW>
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

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
