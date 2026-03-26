function manifest = build_runtime_manifest(cfg)
%BUILD_RUNTIME_MANIFEST Build runtime manifest struct for the current run.

validate_cfg(cfg);

manifest = struct();
manifest.run_name = char(cfg.meta.run_name);
manifest.stage_id = char(cfg.meta.stage_id);
manifest.framework_version = char(cfg.meta.framework_version);
manifest.mode = char(cfg.meta.mode);

manifest.scenario_kind = char(cfg.scenario_def.kind);

manifest.registry_build_mode = char(cfg.trajectory_registry_def.build_mode);
manifest.registry_name = char(cfg.trajectory_registry_def.registry_name);

manifest.task_family_name = char(cfg.task_family_def.family_name);
manifest.task_family_selection_mode = char(cfg.task_family_def.selection_mode);
manifest.task_family_source_registry_name = char(cfg.task_family_def.source_registry_name);

manifest.aggregation_level = char(cfg.aggregation_def.level);
manifest.aggregation_envelope_rule = char(cfg.aggregation_def.envelope_rule);

manifest.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end
