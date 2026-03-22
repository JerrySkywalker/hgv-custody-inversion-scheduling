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
runtime_cfg = local_getfield_or(profile, 'runtime', struct());
force_fresh = logical(local_getfield_or(runtime_cfg, 'force_fresh', local_getfield_or(profile.cache, 'force_fresh', local_getfield_or(cfg_out.runtime, 'force_fresh', false))));
if force_fresh
    cfg_out.milestones.MB_semantic_compare.cache_policy = "force_fresh";
else
    cfg_out.milestones.MB_semantic_compare.cache_policy = string(local_getfield_or(cfg_out.milestones.MB_semantic_compare, 'cache_policy', "all_reuse"));
end
cfg_out.runtime.force_fresh = force_fresh;
cfg_out.runtime.regenerate_all_cache = logical(local_getfield_or(runtime_cfg, 'regenerate_all_cache', local_getfield_or(cfg_out.runtime, 'regenerate_all_cache', false)));
cfg_out.runtime.regenerate_all_export = logical(local_getfield_or(runtime_cfg, 'regenerate_all_export', local_getfield_or(cfg_out.runtime, 'regenerate_all_export', false)));
cfg_out.cache.force_fresh = force_fresh;
cfg_out.cache.reuse_semantic = logical(local_getfield_or(profile.cache, 'reuse_semantic', local_getfield_or(profile.cache, 'reuse_semantic_eval', false)));
cfg_out.cache.reuse_plot = logical(local_getfield_or(profile.cache, 'reuse_plot', local_getfield_or(profile.cache, 'reuse_plotting', false)));
cfg_out.cache.reuse_truth = logical(local_getfield_or(profile.cache, 'reuse_truth', local_getfield_or(cfg_out.cache, 'reuse_truth', true)));
cfg_out.cache.rebuild_all = logical(local_getfield_or(profile.cache, 'rebuild_all', force_fresh));
cfg_out.milestones.MB_semantic_compare.force_fresh = force_fresh;
cfg_out.milestones.MB_semantic_compare.regenerate_all_cache = logical(cfg_out.runtime.regenerate_all_cache);
cfg_out.milestones.MB_semantic_compare.regenerate_all_export = logical(cfg_out.runtime.regenerate_all_export);
cfg_out.milestones.MB_semantic_compare.runtime_profile_name = string(local_getfield_or(runtime_cfg, 'profile_name', local_getfield_or(profile, 'name', "mb_default")));
cfg_out.milestones.MB_semantic_compare.cache_profile.force_fresh = force_fresh;
cfg_out.milestones.MB_semantic_compare.cache_profile.rebuild_all = logical(cfg_out.cache.rebuild_all);
cfg_out.milestones.MB_semantic_compare.cache_profile.reuse_semantic = logical(cfg_out.cache.reuse_semantic);
cfg_out.milestones.MB_semantic_compare.cache_profile.reuse_plot = logical(cfg_out.cache.reuse_plot);
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
