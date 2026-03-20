function cfg_out = apply_mb_search_domain_to_cfg(cfg_in, search_domain)
%APPLY_MB_SEARCH_DOMAIN_TO_CFG Apply a resolved MB search-domain struct to cfg.

if nargin < 1 || isempty(cfg_in)
    cfg_out = milestone_common_defaults();
else
    cfg_out = milestone_common_defaults(cfg_in);
end
if nargin < 2 || isempty(search_domain)
    return;
end

meta = cfg_out.milestones.MB_semantic_compare;
meta.search_domain = search_domain;
meta.search_domain_label = string(format_mb_search_domain_label(search_domain, "short"));
meta.search_domain_detail = string(format_mb_search_domain_label(search_domain, "detailed"));
meta.search_domain_policy = string(local_getfield_or(search_domain, 'policy_name', "profile_default"));
meta.heights_to_run = reshape(local_getfield_or(search_domain, 'height_grid_km', meta.heights_to_run), 1, []);
meta.i_grid_deg = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', meta.i_grid_deg), 1, []);
meta.P_grid = reshape(local_getfield_or(search_domain, 'P_grid', meta.P_grid), 1, []);
meta.T_grid = reshape(local_getfield_or(search_domain, 'T_grid', meta.T_grid), 1, []);
meta.ns_search_min = local_getfield_or(search_domain, 'ns_search_min', NaN);
meta.ns_search_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
meta.ns_search_step = local_getfield_or(search_domain, 'ns_search_step', NaN);
meta.Ns_initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', []), 1, []);
meta.Ns_expand_blocks = local_getfield_or(search_domain, 'Ns_expand_blocks', []);
meta.Ns_hard_max = local_getfield_or(search_domain, 'Ns_hard_max', NaN);
meta.Ns_allow_expand = logical(local_getfield_or(search_domain, 'Ns_allow_expand', false));
meta.solve_domain_mode = string(local_getfield_or(search_domain, 'solve_domain_mode', "fixed"));
meta.expand_strategy = string(local_getfield_or(search_domain, 'expand_strategy', "incremental_blocks"));
meta.expand_trigger_policy = local_getfield_or(search_domain, 'expand_trigger_policy', struct());
meta.expand_stop_policy = local_getfield_or(search_domain, 'expand_stop_policy', struct());
meta.allow_auto_expand_upper = logical(local_getfield_or(search_domain, 'allow_auto_expand_upper', false));
meta.allow_lower_bound_expansion = logical(local_getfield_or(search_domain, 'allow_lower_bound_expansion', false));
meta.max_expand_iterations = local_getfield_or(search_domain, 'max_expand_iterations', NaN);
cfg_out.milestones.MB_semantic_compare = meta;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
