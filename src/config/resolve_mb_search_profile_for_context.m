function profile = resolve_mb_search_profile_for_context(context, cfg)
%RESOLVE_MB_SEARCH_PROFILE_FOR_CONTEXT Resolve an MB search profile for a specific plotting/eval context.

if nargin < 1 || isempty(context)
    context = struct();
end
if nargin < 2
    cfg = [];
end

profile_name = local_getfield_or(context, 'user_selected_profile_name', 'mb_default');
profile = resolve_mb_search_profile(profile_name, cfg);
profile = merge_mb_search_profile_overrides(mb_search_profile_defaults(cfg), profile, "catalog_preset");

figure_family = local_token(local_getfield_or(context, 'figure_family', ""));
semantic_mode = local_token(local_getfield_or(context, 'semantic_mode', profile.semantic_mode));
profile_mode = local_token(local_getfield_or(context, 'profile_mode', local_getfield_or(profile, 'profile_mode', 'expand_default')));
height_km = local_getfield_or(context, 'height_km', []);
sensor_group = local_token(local_getfield_or(context, 'sensor_group', ""));

profile = merge_mb_search_profile_overrides(profile, resolve_mb_search_profile_mode(profile_mode, cfg), "profile_mode:" + profile_mode);

profile = local_apply_named_override(profile, 'figure_family_overrides', figure_family, "figure_family_override");
profile = local_apply_named_override(profile, 'semantic_overrides', semantic_mode, "semantic_override");
profile = local_apply_height_override(profile, height_km);
profile = local_apply_named_override(profile, 'sensor_group_overrides', sensor_group, "sensor_group_override");

if local_should_lock_strict_replica(profile, context)
    strict_override = local_getfield_or(profile, 'strict_replica_override', struct());
    if isempty(fieldnames(strict_override))
        strict_override = local_build_stage05_lock_override(cfg);
    end
    profile = merge_mb_search_profile_overrides(profile, strict_override, "strict_replica_override");
end

autotuned_profile = local_getfield_or(context, 'autotuned_profile_if_any', struct());
if isstruct(autotuned_profile) && ~isempty(fieldnames(autotuned_profile))
    profile = merge_mb_search_profile_overrides(profile, autotuned_profile, "autotune_recommendation");
end

manual_override = local_getfield_or(context, 'cli_manual_override', struct());
if isstruct(manual_override) && ~isempty(fieldnames(manual_override))
    profile = merge_mb_search_profile_overrides(profile, manual_override, "cli_manual_override");
end

profile.metadata.context = context;
profile.metadata.context.figure_family = string(figure_family);
profile.metadata.context.semantic_mode = string(semantic_mode);
profile.metadata.context.profile_mode = string(profile_mode);
profile.metadata.context.sensor_group = string(sensor_group);
if ~isempty(height_km)
    profile.metadata.context.height_km = height_km;
end
profile.search_domain = resolve_mb_search_domain_for_context(profile.metadata.context, cfg, profile);
profile.plot_domain = resolve_mb_plot_domain_for_context(profile.metadata.context, cfg, profile, profile.search_domain);
profile.metadata.profile_source = "resolve_mb_search_profile_for_context";
end

function profile = local_apply_named_override(profile, container_name, token, source_tag)
if strlength(string(token)) == 0
    return;
end
container = local_getfield_or(profile, container_name, struct());
if ~isstruct(container)
    return;
end

field_name = matlab.lang.makeValidName(lower(char(string(token))));
if isfield(container, field_name)
    profile = merge_mb_search_profile_overrides(profile, container.(field_name), source_tag + ":" + field_name);
end
end

function profile = local_apply_height_override(profile, height_km)
if isempty(height_km)
    return;
end
container = local_getfield_or(profile, 'height_overrides', struct());
if ~isstruct(container)
    return;
end

field_name = sprintf('h%d', round(height_km(1)));
if isfield(container, field_name)
    profile = merge_mb_search_profile_overrides(profile, container.(field_name), "height_override:" + field_name);
end
end

function tf = local_should_lock_strict_replica(profile, context)
stage05_replica = local_getfield_or(profile, 'stage05_replica', struct());
if logical(local_getfield_or(stage05_replica, 'strict', false))
    tf = true;
    return;
end

profile_name = local_token(local_getfield_or(profile, 'name', ""));
figure_family = local_token(local_getfield_or(context, 'figure_family', ""));
sensor_group = local_token(local_getfield_or(context, 'sensor_group', ""));
tf = strcmp(profile_name, 'strict_stage05_replica') || ...
    strcmp(profile_name, 'mb_stage05_strict_replica') || ...
    strcmp(figure_family, 'strict_replica') || ...
    strcmp(sensor_group, 'stage05_strict_reference');
end

function override = local_build_stage05_lock_override(cfg)
refs = load_stage05_reference_defaults(cfg);
override = struct( ...
    'semantic_mode', "legacyDG", ...
    'sensor_group_names', {{'stage05_strict_reference'}}, ...
    'height_grid_km', reshape(refs.height_grid_km, 1, []), ...
    'inclination_grid_deg', reshape(refs.inclination_grid_deg, 1, []), ...
    'P_grid', reshape(refs.P_grid, 1, []), ...
    'T_grid', reshape(refs.T_grid, 1, []), ...
    'P_values', reshape(refs.P_grid, 1, []), ...
    'T_values', reshape(refs.T_grid, 1, []), ...
    'plot_xlim_ns', reshape(refs.plot_xlim_ns, 1, []), ...
    'Ns_xlim_plot', reshape(refs.plot_xlim_ns, 1, []), ...
    'Ns_target_window', reshape(refs.plot_xlim_ns, 1, []), ...
    'stage05_replica', struct( ...
        'strict', true, ...
        'use_stage05_plot_semantics', true, ...
        'use_stage05_search_domain', true, ...
        'use_stage05_sensor_defaults', true));
end

function token = local_token(value)
token = lower(strtrim(char(string(value))));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
