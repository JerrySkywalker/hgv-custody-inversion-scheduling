function out = run_stage01_parity(profile)
%RUN_STAGE01_PARITY Build registry and select task set for Stage01 parity.

if nargin < 1 || isempty(profile)
    profile = struct();
end

cfg = build_run_config(profile);
cfg.meta.stage_id = "stage01";

paths = build_output_paths(cfg);
manifest = build_runtime_manifest(cfg);

registry = create_trajectory_registry(cfg.trajectory_registry_def.registry_name);

nominal_spec = cfg.trajectory_registry_def.nominal_spec;
nominal_items = generate_disk_ring_nominal( ...
    nominal_spec.num_points, ...
    nominal_spec.entry_radius_km, ...
    'bundle_id', nominal_spec.bundle_id, ...
    'center_xy_km', nominal_spec.center_xy_km, ...
    'start_angle_deg', nominal_spec.start_angle_deg);

registry = register_trajectories(registry, nominal_items);

heading_spec = cfg.trajectory_registry_def.heading_spec;
if isfield(heading_spec, 'enabled') && logical(heading_spec.enabled)
    heading_items = generate_heading_offset_family( ...
        nominal_items, ...
        heading_spec.offsets_deg);
    registry = register_trajectories(registry, heading_items);
end

selector = cfg.task_family_def.selector;
if ~isfield(selector, 'class_name') || isempty(selector.class_name)
    selector.class_name = cfg.task_family_def.class_name;
end
if ~isfield(selector, 'selection_mode') || isempty(selector.selection_mode)
    selector.selection_mode = cfg.task_family_def.selection_mode;
end

task_set = build_task_family(registry, selector);

out = struct();
out.status = 'PASS';
out.stage_id = char(cfg.meta.stage_id);
out.profile = profile;
out.cfg = cfg;
out.paths = paths;
out.manifest = manifest;
out.registry = registry;
out.registry_summary = summarize_trajectory_registry(registry);
out.task_set = task_set;
out.task_set_summary = summarize_task_family(task_set);
end
