function [cfg_out, profile] = apply_mb_search_profile_to_cfg(cfg_in, profile_in, overrides)
%APPLY_MB_SEARCH_PROFILE_TO_CFG Apply an MB search profile to milestone-B semantic compare cfg.

if nargin < 1 || isempty(cfg_in)
    cfg_out = milestone_common_defaults();
else
    cfg_out = milestone_common_defaults(cfg_in);
end
context = struct();
if nargin >= 3 && isstruct(overrides) && isfield(overrides, 'context') && isstruct(overrides.context)
    context = overrides.context;
    overrides = rmfield(overrides, 'context');
end
if nargin < 2 || isempty(profile_in)
    profile_in = 'mb_default';
end
if isstruct(profile_in) && ~isfield(profile_in, 'name') && ~isfield(profile_in, 'P_grid') && ~isfield(profile_in, 'T_grid')
    context = milestone_common_merge_structs(context, profile_in);
    profile_in = local_getfield_or(context, 'user_selected_profile_name', 'mb_default');
end
if ~isempty(fieldnames(context))
    if ~isfield(context, 'user_selected_profile_name') || strlength(string(context.user_selected_profile_name)) == 0
        context.user_selected_profile_name = string(local_get_profile_name(profile_in));
    end
    profile = resolve_mb_search_profile_for_context(context, cfg_out);
else
    profile = resolve_mb_search_profile(profile_in, cfg_out);
end
if nargin >= 3 && isstruct(overrides) && ~isempty(fieldnames(overrides))
    profile = merge_mb_search_profile_overrides(profile, overrides, "apply_overrides");
end

domain_context = local_getfield_or(profile.metadata, 'context', struct());
if ~isfield(domain_context, 'user_selected_profile_name') || strlength(string(domain_context.user_selected_profile_name)) == 0
    domain_context.user_selected_profile_name = string(profile.name);
end
search_domain = resolve_mb_search_domain_for_context(domain_context, cfg_out, profile);
plot_domain = resolve_mb_plot_domain_for_context(domain_context, cfg_out, profile, search_domain);

cfg_out.milestones.MB_semantic_compare.search_profile = string(profile.name);
cfg_out.milestones.MB_semantic_compare.search_profile_mode = string(profile.profile_mode);
cfg_out.milestones.MB_semantic_compare.search_profile_mode_description = string(profile.profile_mode_description);
cfg_out.milestones.MB_semantic_compare.search_profile_applied = true;
cfg_out.milestones.MB_semantic_compare.search_profile_description = string(profile.description);
cfg_out.milestones.MB_semantic_compare.mode = char(string(profile.semantic_mode));
cfg_out.milestones.MB_semantic_compare.sensor_groups = cellstr(string(profile.sensor_group_names));
cfg_out.milestones.MB_semantic_compare.plot_xlim_heatmap_P = profile.plot_xlim_heatmap_P;
cfg_out.milestones.MB_semantic_compare.plot_ylim_heatmap_i = profile.plot_ylim_heatmap_i;
cfg_out.milestones.MB_semantic_compare.plot_xlim_frontier_i = profile.plot_xlim_frontier_i;
cfg_out.milestones.MB_semantic_compare.plot_xlim_hi = profile.plot_xlim_hi;
cfg_out.milestones.MB_semantic_compare.plot_ylim_hi = profile.plot_ylim_hi;
cfg_out.milestones.MB_semantic_compare.Ns_target_window = reshape(profile.Ns_target_window, 1, []);
cfg_out.milestones.MB_semantic_compare.auto_tune = profile.auto_tune;
cfg_out.milestones.MB_semantic_compare.cache_profile = profile.cache;
cfg_out.milestones.MB_semantic_compare.stage05_replica = profile.stage05_replica;
cfg_out.milestones.MB_semantic_compare.run_dense_local = logical(profile.dense_local.enabled);
cfg_out.milestones.MB_semantic_compare.dense_local_sensor_groups = cellstr(string(profile.dense_local.sensor_group_names));
cfg_out.milestones.MB_semantic_compare.dense_local_heights = reshape(profile.dense_local.height_grid_km, 1, []);
cfg_out.milestones.MB_semantic_compare.dense_local_anchor_h_km = profile.dense_local.anchor_h_km;
cfg_out.milestones.MB_semantic_compare.dense_local_i_deg = reshape(profile.dense_local.inclination_grid_deg, 1, []);
cfg_out.milestones.MB_semantic_compare.dense_local_P = reshape(profile.dense_local.P_grid, 1, []);
cfg_out.milestones.MB_semantic_compare.dense_local_T = reshape(profile.dense_local.T_grid, 1, []);
cfg_out.milestones.MB_semantic_compare.search_profile_metadata = profile.metadata;
cfg_out.milestones.MB_semantic_compare.search_profile_context = local_getfield_or(profile.metadata, 'context', struct());
cfg_out.milestones.MB_semantic_compare.search_profile_override_sources = cellstr(string(local_getfield_or(profile.metadata, 'override_sources', {})));
cfg_out = apply_mb_search_domain_to_cfg(cfg_out, search_domain);
cfg_out = apply_mb_plot_domain_to_cfg(cfg_out, plot_domain);
end

function name = local_get_profile_name(profile_in)
if isstruct(profile_in) && isfield(profile_in, 'name')
    name = profile_in.name;
else
    name = profile_in;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
