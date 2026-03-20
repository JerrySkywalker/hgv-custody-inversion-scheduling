function label = format_mb_search_profile_label(profile_in, cfg, detail_level)
%FORMAT_MB_SEARCH_PROFILE_LABEL Human-readable MB search-profile label.

if nargin < 1 || isempty(profile_in)
    profile_in = 'mb_default';
end
if nargin < 2
    cfg = [];
end
if nargin < 3 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

if isstruct(profile_in)
    profile = profile_in;
else
    profile = get_mb_search_profile(profile_in, cfg);
end

name = char(string(local_getfield_or(profile, 'name', "custom_profile")));
semantic_mode = char(string(local_getfield_or(profile, 'semantic_mode', "")));
profile_mode = char(string(local_getfield_or(profile, 'profile_mode', "")));
height_grid = reshape(local_getfield_or(profile, 'height_grid_km', []), 1, []);
P_grid = reshape(local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', [])), 1, []);
T_grid = reshape(local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', [])), 1, []);
plot_xlim = reshape(local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), 1, []);
ns_initial = reshape(local_getfield_or(profile, 'Ns_initial_range', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_initial_range', [])), 1, []);
ns_hard_max = local_getfield_or(profile, 'Ns_hard_max', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_hard_max', NaN));
ns_allow_expand = logical(local_getfield_or(profile, 'Ns_allow_expand', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_allow_expand', false)));
expand_blocks = local_getfield_or(profile, 'Ns_expand_blocks', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_expand_blocks', []));

Ns_min = NaN;
Ns_max = NaN;
if numel(ns_initial) >= 3
    Ns_min = ns_initial(1);
    Ns_max = ns_initial(3);
elseif ~isempty(P_grid) && ~isempty(T_grid)
    ns_grid = unique(P_grid(:) * T_grid(:).');
    Ns_min = min(ns_grid(:));
    Ns_max = max(ns_grid(:));
end

short_parts = strings(0, 1);
if strlength(string(profile_mode)) > 0
    short_parts(end + 1, 1) = string(sprintf('mode=%s', profile_mode));
end
if strlength(string(semantic_mode)) > 0
    short_parts(end + 1, 1) = string(sprintf('semantic=%s', semantic_mode));
end
if ~isnan(Ns_min) && ~isnan(Ns_max)
    short_parts(end + 1, 1) = string(sprintf('Ns=[%g,%g]', Ns_min, Ns_max));
end
if isfinite(ns_hard_max)
    short_parts(end + 1, 1) = string(sprintf('hardMax=%g', ns_hard_max));
end
if isstruct(expand_blocks) && ~isempty(expand_blocks)
    short_parts(end + 1, 1) = string(sprintf('blocks=%d', numel(expand_blocks)));
end
short_parts(end + 1, 1) = "expand=" + string(local_onoff(ns_allow_expand));
if ~isempty(plot_xlim)
    short_parts(end + 1, 1) = string(sprintf('xlim=[%g,%g]', plot_xlim(1), plot_xlim(end)));
end
if logical(local_getfield_or(local_getfield_or(profile, 'stage05_replica', struct()), 'strict', false))
    short_parts(end + 1, 1) = "stage05 lock";
end

detail_parts = short_parts;
if ~isempty(height_grid)
    detail_parts(end + 1, 1) = string(sprintf('h=%s', mat2str(height_grid)));
end
if ~isempty(P_grid)
    detail_parts(end + 1, 1) = string(sprintf('P=%s', mat2str(P_grid)));
end
if ~isempty(T_grid)
    detail_parts(end + 1, 1) = string(sprintf('T=%s', mat2str(T_grid)));
end
if numel(ns_initial) >= 3
    detail_parts(end + 1, 1) = string(sprintf('Ns0=[%g:%g:%g]', ns_initial(1), ns_initial(2), ns_initial(3)));
end
if isstruct(expand_blocks) && ~isempty(expand_blocks)
    detail_parts(end + 1, 1) = "expandBlocks=" + local_format_expand_blocks(expand_blocks);
end
if isfield(profile, 'description') && strlength(string(profile.description)) > 0
    detail_parts(end + 1, 1) = string(profile.description);
end
if isfield(profile, 'profile_mode_description') && strlength(string(profile.profile_mode_description)) > 0
    detail_parts(end + 1, 1) = string(profile.profile_mode_description);
end

if strcmpi(char(string(detail_level)), 'detailed')
    label_parts = detail_parts;
else
    label_parts = short_parts;
end

if isempty(label_parts)
    label = string(name);
else
    label = string(sprintf('%s (%s)', name, strjoin(cellstr(label_parts), ', ')));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function txt = local_onoff(tf)
if tf
    txt = "on";
else
    txt = "off";
end
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
