function cfg = framework_defaults()
%FRAMEWORK_DEFAULTS Default configuration for the rewritten framework.
%   This function returns the framework-native default runtime schema for
%   the static-first rewrite phase.

cfg = struct();

cfg.meta = struct();
cfg.meta.framework_version = "rewrite-v1";
cfg.meta.stage_id = "stage00";
cfg.meta.run_name = "unnamed_run";
cfg.meta.mode = "formal";

cfg.scenario_def = struct();
cfg.scenario_def.kind = "disk_region";
cfg.scenario_def.frame = "regional_geodetic";
cfg.scenario_def.region_id = "protected_disk_01";

cfg.trajectory_registry_def = struct();
cfg.trajectory_registry_def.build_mode = "generators";
cfg.trajectory_registry_def.registry_name = "default_registry";
cfg.trajectory_registry_def.generator_specs = {};

cfg.task_family_def = struct();
cfg.task_family_def.family_name = "nominal";
cfg.task_family_def.selection_mode = "full";
cfg.task_family_def.source_registry_name = "default_registry";
cfg.task_family_def.selector = struct();

cfg.aggregation_def = struct();
cfg.aggregation_def.level = "design_over_family";
cfg.aggregation_def.group_keys = {'scenario_group', 'family_name', 'i_deg'};
cfg.aggregation_def.envelope_rule = "max_over_same_Ns_within_fixed_group";

cfg.runtime_def = struct();
cfg.runtime_def.max_cases = [];
cfg.runtime_def.max_designs = [];
cfg.runtime_def.parallel = false;

cfg.output_def = struct();
cfg.output_def.root_dir = "outputs";
cfg.output_def.chapter = "chapter4";
cfg.output_def.namespace = "static_parity";
end
