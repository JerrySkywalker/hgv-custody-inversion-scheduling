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
cfg.scenario_def.scene_mode = "local_disk";
cfg.scenario_def.anchor_lat_deg = NaN;
cfg.scenario_def.anchor_lon_deg = NaN;
cfg.scenario_def.anchor_h_m = NaN;

cfg.trajectory_registry_def = struct();
cfg.trajectory_registry_def.build_mode = "generators";
cfg.trajectory_registry_def.registry_name = "default_registry";
cfg.trajectory_registry_def.generator_specs = {};

cfg.trajectory_registry_def.nominal_spec = struct();
cfg.trajectory_registry_def.nominal_spec.num_points = 12;
cfg.trajectory_registry_def.nominal_spec.entry_radius_km = 3000;
cfg.trajectory_registry_def.nominal_spec.bundle_id = "ring12";
cfg.trajectory_registry_def.nominal_spec.center_xy_km = [0, 0];
cfg.trajectory_registry_def.nominal_spec.start_angle_deg = 0;
cfg.trajectory_registry_def.nominal_spec.scene_mode = "local_disk";
cfg.trajectory_registry_def.nominal_spec.anchor_lat_deg = NaN;
cfg.trajectory_registry_def.nominal_spec.anchor_lon_deg = NaN;
cfg.trajectory_registry_def.nominal_spec.anchor_h_m = NaN;

cfg.trajectory_registry_def.heading_spec = struct();
cfg.trajectory_registry_def.heading_spec.enabled = false;
cfg.trajectory_registry_def.heading_spec.offsets_deg = [0; -30; 30; -60; 60];

cfg.trajectory_registry_def.critical_spec = struct();
cfg.trajectory_registry_def.critical_spec.enabled = false;
cfg.trajectory_registry_def.critical_spec.entry_radius_km = 3000;
cfg.trajectory_registry_def.critical_spec.center_xy_km = [0, 0];
cfg.trajectory_registry_def.critical_spec.scene_mode = "local_disk";
cfg.trajectory_registry_def.critical_spec.anchor_lat_deg = NaN;
cfg.trajectory_registry_def.critical_spec.anchor_lon_deg = NaN;
cfg.trajectory_registry_def.critical_spec.anchor_h_m = NaN;

cfg.task_family_def = struct();
cfg.task_family_def.class_name = "nominal";
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
