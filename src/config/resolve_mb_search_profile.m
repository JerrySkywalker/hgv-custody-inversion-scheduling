function profile = resolve_mb_search_profile(user_input, cfg)
%RESOLVE_MB_SEARCH_PROFILE Resolve user input into a normalized MB search profile.

if nargin < 1 || isempty(user_input)
    profile = merge_mb_search_profile_overrides(mb_search_profile_defaults(cfg), get_mb_search_profile('mb_default', cfg), "resolve_default");
    return;
end

if isstruct(user_input)
    if local_looks_like_context(user_input)
        profile = resolve_mb_search_profile_for_context(user_input, cfg);
    else
        profile = merge_mb_search_profile_overrides(mb_search_profile_defaults(cfg), user_input, "resolve_struct");
    end
elseif ischar(user_input) || isstring(user_input)
    profile = merge_mb_search_profile_overrides(mb_search_profile_defaults(cfg), get_mb_search_profile(user_input, cfg), "resolve_named");
else
    error('Unsupported MB search profile input type.');
end
end

function tf = local_looks_like_context(S)
if isfield(S, 'name') || isfield(S, 'P_grid') || isfield(S, 'T_grid') || isfield(S, 'height_grid_km')
    tf = false;
    return;
end
context_fields = { ...
    'figure_family', ...
    'semantic_mode', ...
    'height_km', ...
    'sensor_group', ...
    'user_selected_profile_name', ...
    'autotuned_profile_if_any', ...
    'cli_manual_override'};
tf = any(isfield(S, context_fields));
end
