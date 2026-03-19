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

Ns_min = NaN;
Ns_max = NaN;
if ~isempty(P_grid) && ~isempty(T_grid)
    ns_grid = unique(P_grid(:) * T_grid(:).');
    Ns_min = min(ns_grid(:));
    Ns_max = max(ns_grid(:));
end

short_parts = strings(0, 1);
if strlength(string(profile_mode)) > 0
    short_parts(end + 1, 1) = string(sprintf('mode=%s', profile_mode)); %#ok<AGROW>
end
if strlength(string(semantic_mode)) > 0
    short_parts(end + 1, 1) = string(sprintf('semantic=%s', semantic_mode)); %#ok<AGROW>
end
if ~isnan(Ns_min) && ~isnan(Ns_max)
    short_parts(end + 1, 1) = string(sprintf('Ns=[%g,%g]', Ns_min, Ns_max)); %#ok<AGROW>
end
if ~isempty(plot_xlim)
    short_parts(end + 1, 1) = string(sprintf('xlim=[%g,%g]', plot_xlim(1), plot_xlim(end))); %#ok<AGROW>
end
if logical(local_getfield_or(local_getfield_or(profile, 'stage05_replica', struct()), 'strict', false))
    short_parts(end + 1, 1) = "stage05 lock"; %#ok<AGROW>
end

detail_parts = short_parts;
if ~isempty(height_grid)
    detail_parts(end + 1, 1) = string(sprintf('h=%s', mat2str(height_grid))); %#ok<AGROW>
end
if ~isempty(P_grid)
    detail_parts(end + 1, 1) = string(sprintf('P=%s', mat2str(P_grid))); %#ok<AGROW>
end
if ~isempty(T_grid)
    detail_parts(end + 1, 1) = string(sprintf('T=%s', mat2str(T_grid))); %#ok<AGROW>
end
if isfield(profile, 'description') && strlength(string(profile.description)) > 0
    detail_parts(end + 1, 1) = string(profile.description); %#ok<AGROW>
end
if isfield(profile, 'profile_mode_description') && strlength(string(profile.profile_mode_description)) > 0
    detail_parts(end + 1, 1) = string(profile.profile_mode_description); %#ok<AGROW>
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
