function out = run_mb_final_repair_fullnight(tag, sensor_groups, family_set)
%RUN_MB_FINAL_REPAIR_FULLNIGHT Run the final-repair MB fullnight profile into a dedicated fresh root.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) + "_fullnight";
end
if nargin < 2 || isempty(sensor_groups)
    sensor_groups = {'baseline'};
end
if nargin < 3 || isempty(family_set)
    family_set = {'nominal'};
end

cfg = milestone_common_defaults();
[cfg, profile] = apply_mb_search_profile_to_cfg(cfg, 'mb_final_repair_fullnight');
milestone_id = "MB_" + string(tag);
cfg.milestones.MB_semantic_compare.milestone_id = char(milestone_id);
cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
cfg.milestones.MB_semantic_compare.mode = 'comparison';
cfg.milestones.MB_semantic_compare.sensor_groups = cellstr(string(sensor_groups));
cfg.milestones.MB_semantic_compare.family_set = cellstr(string(family_set));
cfg.milestones.MB_semantic_compare.force_fresh = true;
cfg.milestones.MB_semantic_compare.regenerate_all_cache = true;
cfg.milestones.MB_semantic_compare.regenerate_all_export = true;
cfg.milestones.MB_semantic_compare.runtime_profile_name = string(profile.name);
cfg.milestones.MB_semantic_compare.cache_policy = 'force_fresh';
cfg.milestones.MB_semantic_compare.cache_profile.force_fresh = true;
cfg.milestones.MB_semantic_compare.cache_profile.rebuild_all = true;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_semantic = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_plot = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_semantic_eval = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_plotting = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_tune_cache = false;
cfg.runtime.force_fresh = true;
cfg.runtime.regenerate_all_cache = true;
cfg.runtime.regenerate_all_export = true;
cfg.cache.force_fresh = true;
cfg.cache.reuse_semantic = false;
cfg.cache.reuse_plot = false;
cfg.cache.rebuild_all = true;
cfg.runtime.figure_visibility_mode = 'headless';

out = milestone_B_semantic_compare(cfg);
paths = mb_output_paths(cfg, cfg.milestones.MB_semantic_compare.milestone_id, cfg.milestones.MB_semantic_compare.title);
out.profile_name = string(profile.name);
out.fresh_root = string(paths.milestone_root);
out.tables_root = string(paths.tables);
out.figures_root = string(paths.figures);
end
