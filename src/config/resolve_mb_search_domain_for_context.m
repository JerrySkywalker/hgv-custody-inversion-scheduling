function search_domain = resolve_mb_search_domain_for_context(context, cfg, profile)
%RESOLVE_MB_SEARCH_DOMAIN_FOR_CONTEXT Resolve the runtime MB search domain for a context.

if nargin < 1 || isempty(context)
    context = struct();
end
if nargin < 2
    cfg = [];
end
if nargin < 3 || isempty(profile)
    profile = [];
end

if isempty(profile)
    profile_name = local_getfield_or(context, 'user_selected_profile_name', 'mb_default');
    profile = resolve_mb_search_profile(profile_name, cfg);
end

strict_lock = logical(local_getfield_or(local_getfield_or(profile, 'stage05_replica', struct()), 'strict', false));
policy_name = string(local_getfield_or(context, 'search_domain_policy', ""));
if strlength(policy_name) == 0
    if strict_lock
        policy_name = "strict_stage05_reference";
    else
        policy_name = "profile_default";
    end
end

search_domain = struct();
search_domain.policy_name = policy_name;
search_domain.profile_name = string(local_getfield_or(profile, 'name', "mb_default"));
search_domain.profile_mode = string(local_getfield_or(profile, 'profile_mode', "debug"));
search_domain.semantic_mode = string(local_getfield_or(profile, 'semantic_mode', ""));
search_domain.sensor_group_names = cellstr(string(local_getfield_or(profile, 'sensor_group_names', {'baseline'})));
search_domain.height_grid_km = reshape(local_getfield_or(profile, 'height_grid_km', []), 1, []);
search_domain.inclination_grid_deg = reshape(local_getfield_or(profile, 'inclination_grid_deg', []), 1, []);
search_domain.P_grid = reshape(local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', [])), 1, []);
search_domain.T_grid = reshape(local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', [])), 1, []);
search_domain.allow_auto_expand_upper = logical(local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'enabled', false)) && ~strict_lock;
search_domain.allow_lower_bound_expansion = false;
search_domain.expand_step_P = local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'expand_step_P', 2);
search_domain.expand_step_T = local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'expand_step_T', 4);
search_domain.max_expand_iterations = local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'max_iterations', 5);
search_domain.strict_stage05_reference = strict_lock;

profile_search_domain = local_getfield_or(profile, 'search_domain', struct());
if isstruct(profile_search_domain) && ~isempty(fieldnames(profile_search_domain))
    search_domain = milestone_common_merge_structs(search_domain, profile_search_domain);
end

context_override = local_getfield_or(context, 'search_domain_override', struct());
if isstruct(context_override) && ~isempty(fieldnames(context_override))
    search_domain = milestone_common_merge_structs(search_domain, context_override);
end

search_domain = local_normalize_search_domain(search_domain);
switch lower(char(string(policy_name)))
    case 'strict_stage05_reference'
        search_domain.strict_stage05_reference = true;
        search_domain.allow_auto_expand_upper = false;
    case 'expand_if_unsaturated'
        search_domain.allow_auto_expand_upper = true;
    case 'custom'
        % keep the caller-provided grids and expansion flags as-is
    otherwise
        % profile_default and other catalog policies keep the resolved defaults
end
if logical(local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'enabled', false)) && ~strict_lock
    search_domain.allow_auto_expand_upper = true;
end
search_domain.summary_short = format_mb_search_domain_label(search_domain, "short");
search_domain.summary_detailed = format_mb_search_domain_label(search_domain, "detailed");
search_domain.metadata = struct( ...
    'resolver', "resolve_mb_search_domain_for_context", ...
    'policy_name', string(search_domain.policy_name), ...
    'profile_name', string(search_domain.profile_name), ...
    'profile_mode', string(search_domain.profile_mode), ...
    'strict_stage05_reference', logical(search_domain.strict_stage05_reference), ...
    'context', context);
end

function search_domain = local_normalize_search_domain(search_domain)
search_domain.height_grid_km = reshape(local_getfield_or(search_domain, 'height_grid_km', []), 1, []);
search_domain.inclination_grid_deg = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', []), 1, []);
search_domain.P_grid = reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []);
search_domain.T_grid = reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []);
search_domain.sensor_group_names = cellstr(string(local_getfield_or(search_domain, 'sensor_group_names', {'baseline'})));

ns_grid = local_build_ns_grid(search_domain.P_grid, search_domain.T_grid);
if isempty(ns_grid)
    ns_min = NaN;
    ns_max = NaN;
    ns_step = NaN;
else
    ns_min = min(ns_grid);
    ns_max = max(ns_grid);
    ns_step = local_estimate_ns_step(ns_grid);
end

search_domain.ns_search_min = local_getfield_or(search_domain, 'ns_search_min', ns_min);
search_domain.ns_search_max = local_getfield_or(search_domain, 'ns_search_max', ns_max);
search_domain.ns_search_step = local_getfield_or(search_domain, 'ns_search_step', ns_step);
search_domain.ns_search_grid = ns_grid;
search_domain.expand_step_ns = local_getfield_or(search_domain, 'expand_step_ns', search_domain.ns_search_step);
end

function ns_grid = local_build_ns_grid(P_grid, T_grid)
if isempty(P_grid) || isempty(T_grid)
    ns_grid = [];
    return;
end
ns_grid = unique(reshape(P_grid(:) * T_grid(:).', 1, []), 'sorted');
end

function ns_step = local_estimate_ns_step(ns_grid)
if numel(ns_grid) < 2
    ns_step = NaN;
    return;
end
diffs = diff(unique(round(ns_grid(:).')));
diffs = diffs(diffs > 0);
if isempty(diffs)
    ns_step = NaN;
    return;
end
ns_step = diffs(1);
for idx = 2:numel(diffs)
    ns_step = gcd(ns_step, diffs(idx));
end
if ns_step <= 0
    ns_step = min(diffs);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
