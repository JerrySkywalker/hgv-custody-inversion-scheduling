function cfg = build_run_config(profile)
%BUILD_RUN_CONFIG Build strict framework runtime configuration.
%   cfg = BUILD_RUN_CONFIG(profile)
%
%   The build process is:
%     1) load framework defaults
%     2) validate lightweight profile
%     3) deep merge profile into defaults
%     4) normalize selected meta fields
%     5) validate strict cfg

if nargin < 1 || isempty(profile)
    profile = struct();
end

validate_profile(profile);

cfg = framework_defaults();
cfg = merge_struct_deep(cfg, profile);

cfg.meta.framework_version = string(cfg.meta.framework_version);
cfg.meta.stage_id = string(cfg.meta.stage_id);
cfg.meta.run_name = string(cfg.meta.run_name);
cfg.meta.mode = string(cfg.meta.mode);

cfg.scenario_def.kind = string(cfg.scenario_def.kind);

cfg.trajectory_registry_def.build_mode = string(cfg.trajectory_registry_def.build_mode);
cfg.trajectory_registry_def.registry_name = string(cfg.trajectory_registry_def.registry_name);

cfg.task_family_def.family_name = string(cfg.task_family_def.family_name);
cfg.task_family_def.selection_mode = string(cfg.task_family_def.selection_mode);
cfg.task_family_def.source_registry_name = string(cfg.task_family_def.source_registry_name);

cfg.aggregation_def.level = string(cfg.aggregation_def.level);
cfg.aggregation_def.envelope_rule = string(cfg.aggregation_def.envelope_rule);

cfg.output_def.root_dir = string(cfg.output_def.root_dir);
cfg.output_def.chapter = string(cfg.output_def.chapter);
cfg.output_def.namespace = string(cfg.output_def.namespace);

validate_cfg(cfg);
end
