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
search_domain.profile_mode = string(local_getfield_or(profile, 'profile_mode', "expand_default"));
search_domain.semantic_mode = string(local_getfield_or(profile, 'semantic_mode', ""));
search_domain.sensor_group_names = cellstr(string(local_getfield_or(profile, 'sensor_group_names', {'baseline'})));
search_domain.height_grid_km = reshape(local_getfield_or(profile, 'height_grid_km', []), 1, []);
search_domain.inclination_grid_deg = reshape(local_getfield_or(profile, 'inclination_grid_deg', []), 1, []);
search_domain.P_grid = reshape(local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', [])), 1, []);
search_domain.T_grid = reshape(local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', [])), 1, []);
search_domain.Ns_initial_range = reshape(local_getfield_or(profile, 'Ns_initial_range', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_initial_range', [])), 1, []);
search_domain.Ns_expand_blocks = local_normalize_expand_blocks(local_getfield_or(profile, 'Ns_expand_blocks', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_expand_blocks', [])));
search_domain.Ns_hard_max = local_getfield_or(profile, 'Ns_hard_max', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_hard_max', NaN));
search_domain.Ns_allow_expand = logical(local_getfield_or(profile, 'Ns_allow_expand', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'Ns_allow_expand', false))) && ~strict_lock;
search_domain.solve_domain_mode = string(local_getfield_or(profile, 'solve_domain_mode', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'solve_domain_mode', "fixed")));
search_domain.expand_strategy = string(local_getfield_or(profile, 'expand_strategy', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'expand_strategy', "incremental_blocks")));
search_domain.expand_trigger_policy = local_getfield_or(profile, 'expand_trigger_policy', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'expand_trigger_policy', struct()));
search_domain.expand_stop_policy = local_getfield_or(profile, 'expand_stop_policy', local_getfield_or(local_getfield_or(profile, 'search_domain', struct()), 'expand_stop_policy', struct()));
search_domain.allow_auto_expand_upper = search_domain.Ns_allow_expand;
search_domain.allow_lower_bound_expansion = false;
search_domain.expand_step_P = local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'expand_step_P', 2);
search_domain.expand_step_T = local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'expand_step_T', 4);
search_domain.max_expand_iterations = max(numel(search_domain.Ns_expand_blocks), local_getfield_or(local_getfield_or(profile, 'auto_tune', struct()), 'max_iterations', 5));
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
        search_domain.Ns_allow_expand = false;
        search_domain.solve_domain_mode = "fixed";
    case 'expand_if_unsaturated'
        search_domain.allow_auto_expand_upper = true;
        search_domain.Ns_allow_expand = true;
        search_domain.solve_domain_mode = "expandable";
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
search_domain.Ns_initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', []), 1, []);
search_domain.Ns_expand_blocks = local_normalize_expand_blocks(local_getfield_or(search_domain, 'Ns_expand_blocks', []));
search_domain.Ns_hard_max = local_getfield_or(search_domain, 'Ns_hard_max', NaN);
search_domain.Ns_allow_expand = logical(local_getfield_or(search_domain, 'Ns_allow_expand', false));
search_domain.solve_domain_mode = string(local_getfield_or(search_domain, 'solve_domain_mode', "fixed"));
search_domain.expand_strategy = string(local_getfield_or(search_domain, 'expand_strategy', "incremental_blocks"));

ns_grid = local_build_ns_grid(search_domain.P_grid, search_domain.T_grid);
if numel(search_domain.Ns_initial_range) >= 3 && all(isfinite(search_domain.Ns_initial_range(1:3)))
    ns_min = search_domain.Ns_initial_range(1);
    ns_step = search_domain.Ns_initial_range(2);
    ns_max = search_domain.Ns_initial_range(3);
    ns_grid = ns_min:ns_step:ns_max;
elseif isempty(ns_grid)
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

function blocks = local_normalize_expand_blocks(blocks_in)
if isempty(blocks_in)
    blocks = repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0);
    return;
end
blocks = blocks_in;
for idx = 1:numel(blocks)
    blocks(idx).name = string(local_getfield_or(blocks(idx), 'name', "block" + idx));
    blocks(idx).ns_min = local_getfield_or(blocks(idx), 'ns_min', NaN);
    blocks(idx).ns_step = local_getfield_or(blocks(idx), 'ns_step', NaN);
    blocks(idx).ns_max = local_getfield_or(blocks(idx), 'ns_max', NaN);
    ns_values = local_getfield_or(blocks(idx), 'ns_values', []);
    if isempty(ns_values) && all(isfinite([blocks(idx).ns_min, blocks(idx).ns_step, blocks(idx).ns_max]))
        ns_values = blocks(idx).ns_min:blocks(idx).ns_step:blocks(idx).ns_max;
    end
    blocks(idx).ns_values = reshape(ns_values, 1, []);
end
end
