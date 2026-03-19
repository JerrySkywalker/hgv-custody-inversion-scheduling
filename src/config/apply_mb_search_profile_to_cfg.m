function [cfg_out, profile] = apply_mb_search_profile_to_cfg(cfg_in, profile_in, overrides)
%APPLY_MB_SEARCH_PROFILE_TO_CFG Apply an MB search profile to milestone-B semantic compare cfg.

if nargin < 1 || isempty(cfg_in)
    cfg_out = milestone_common_defaults();
else
    cfg_out = milestone_common_defaults(cfg_in);
end
if nargin < 2 || isempty(profile_in)
    profile = resolve_mb_search_profile('mb_default', cfg_out);
else
    profile = resolve_mb_search_profile(profile_in, cfg_out);
end
if nargin >= 3 && isstruct(overrides) && ~isempty(fieldnames(overrides))
    profile = milestone_common_merge_structs(profile, overrides);
end

cfg_out.milestones.MB_semantic_compare.search_profile = string(profile.name);
cfg_out.milestones.MB_semantic_compare.search_profile_applied = true;
cfg_out.milestones.MB_semantic_compare.search_profile_description = string(profile.description);
cfg_out.milestones.MB_semantic_compare.mode = char(string(profile.semantic_mode));
cfg_out.milestones.MB_semantic_compare.sensor_groups = cellstr(string(profile.sensor_group_names));
cfg_out.milestones.MB_semantic_compare.heights_to_run = reshape(profile.height_grid_km, 1, []);
cfg_out.milestones.MB_semantic_compare.i_grid_deg = reshape(profile.inclination_grid_deg, 1, []);
cfg_out.milestones.MB_semantic_compare.P_grid = reshape(profile.P_grid, 1, []);
cfg_out.milestones.MB_semantic_compare.T_grid = reshape(profile.T_grid, 1, []);
cfg_out.milestones.MB_semantic_compare.plot_xlim_ns = profile.plot_xlim_ns;
cfg_out.milestones.MB_semantic_compare.plot_ylim_passratio = profile.plot_ylim_passratio;
cfg_out.milestones.MB_semantic_compare.plot_xlim_heatmap_P = profile.plot_xlim_heatmap_P;
cfg_out.milestones.MB_semantic_compare.plot_ylim_heatmap_i = profile.plot_ylim_heatmap_i;
cfg_out.milestones.MB_semantic_compare.plot_xlim_frontier_i = profile.plot_xlim_frontier_i;
cfg_out.milestones.MB_semantic_compare.plot_xlim_hi = profile.plot_xlim_hi;
cfg_out.milestones.MB_semantic_compare.plot_ylim_hi = profile.plot_ylim_hi;
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
end
