function out = run_mb_full_rebuild_and_plot_closure(tag)
%RUN_MB_FULL_REBUILD_AND_PLOT_CLOSURE Run strict replica plus multi-height MB full rebuild closure.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = "20260323_fullrebuild";
end
tag = string(tag);

strict_cfg = milestone_common_defaults();
[strict_cfg, ~, ~] = mb_cli_configure_search_profile(strict_cfg, false, struct( ...
    'run_mode', 'strict_stage05_validation_only', ...
    'profile_name', 'strict_stage05_replica', ...
    'profile_mode', 'strict_replica'));
strict_cfg.milestones.MB_semantic_compare.milestone_id = char("MB_" + tag + "_strict");
strict_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
strict_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
strict_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
strict_cfg.runtime.figure_visibility_mode = 'headless';
strict_out = run_milestone_B_semantic_compare(strict_cfg, false);

baseline_cfg = milestone_common_defaults();
[baseline_cfg, profile] = apply_mb_search_profile_to_cfg(baseline_cfg, 'mb_final_repair_fullnight');
baseline_cfg.milestones.MB_semantic_compare.milestone_id = char("MB_" + tag + "_baseline");
baseline_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
baseline_cfg.milestones.MB_semantic_compare.mode = 'comparison';
baseline_cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
baseline_cfg.milestones.MB_semantic_compare.heights_to_run = [500, 750, 1000];
baseline_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
baseline_cfg.milestones.MB_semantic_compare.force_rebuild_all_cache = true;
baseline_cfg.milestones.MB_semantic_compare.force_fresh = true;
baseline_cfg.milestones.MB_semantic_compare.regenerate_all_cache = true;
baseline_cfg.milestones.MB_semantic_compare.regenerate_all_export = true;
baseline_cfg.milestones.MB_semantic_compare.runtime_profile_name = string(profile.name);
baseline_cfg.runtime.figure_visibility_mode = 'headless';
baseline_out = milestone_B_semantic_compare(baseline_cfg);

strict_paths = mb_output_paths(strict_cfg, strict_cfg.milestones.MB_semantic_compare.milestone_id, strict_cfg.milestones.MB_semantic_compare.title);
baseline_paths = mb_output_paths(baseline_cfg, baseline_cfg.milestones.MB_semantic_compare.milestone_id, baseline_cfg.milestones.MB_semantic_compare.title);

out = struct();
out.tag = tag;
out.strict_root = string(strict_paths.milestone_root);
out.baseline_root = string(baseline_paths.milestone_root);
out.strict = strict_out;
out.baseline = baseline_out;
out.profile_name = string(profile.name);
end
