function out = run_stage01_parity(profile)
%RUN_STAGE01_PARITY Full Stage01 parity runner for registry + casebank view.

if nargin < 1 || isempty(profile)
    profile = struct();
end

cfg = build_run_config(profile);
cfg.meta.stage_id = "stage01";

paths = build_output_paths(cfg);
manifest = build_runtime_manifest(cfg);

source_bank = build_source_bank(cfg);
source_bank_summary = summarize_source_bank(source_bank);

registry = create_trajectory_registry(cfg.trajectory_registry_def.registry_name);

nominal_items = table();
nominal_items_created = false;

for k = 1:source_bank.source_count
    src = source_bank.sources(k);

    if ~logical(src.enabled)
        continue;
    end

    switch char(string(src.source_id))
        case 'src_nominal_ring'
            spec = src.spec;
            nominal_items = generate_disk_ring_nominal( ...
                spec.num_points, ...
                spec.entry_radius_km, ...
                'bundle_id', spec.bundle_id, ...
                'center_xy_km', spec.center_xy_km, ...
                'start_angle_deg', spec.start_angle_deg);

            registry = register_trajectories(registry, nominal_items);
            nominal_items_created = true;

        case 'src_heading_bundle'
            if ~nominal_items_created
                error('run_stage01_parity:MissingNominalDependency', ...
                    'Heading source requires nominal items, but nominal source has not been materialized.');
            end

            spec = src.spec;
            heading_items = generate_heading_offset_family( ...
                nominal_items, ...
                spec.offsets_deg);

            registry = register_trajectories(registry, heading_items);

        case 'src_critical_tracks'
            spec = src.spec;
            critical_items = generate_stage01_critical_tracks( ...
                'entry_radius_km', spec.entry_radius_km, ...
                'center_xy_km', spec.center_xy_km);

            registry = register_trajectories(registry, critical_items);

        otherwise
            error('run_stage01_parity:UnknownSource', ...
                'Unknown source_id: %s', char(string(src.source_id)));
    end
end

selector = cfg.task_family_def.selector;
if ~isfield(selector, 'class_name') || isempty(selector.class_name)
    selector.class_name = cfg.task_family_def.class_name;
end
if ~isfield(selector, 'selection_mode') || isempty(selector.selection_mode)
    selector.selection_mode = cfg.task_family_def.selection_mode;
end

task_set = build_task_family(registry, selector);
casebank_view = build_stage01_casebank_view(registry);
casebank_summary = summarize_stage01_casebank_view(casebank_view);

out = struct();
out.status = 'PASS';
out.stage_id = char(cfg.meta.stage_id);
out.profile = profile;
out.cfg = cfg;
out.paths = paths;
out.manifest = manifest;

out.source_bank = source_bank;
out.source_bank_summary = source_bank_summary;

out.registry = registry;
out.registry_summary = summarize_trajectory_registry(registry);

out.task_set = task_set;
out.task_set_summary = summarize_task_family(task_set);

out.casebank_view = casebank_view;
out.casebank_summary = casebank_summary;
end

function summary = summarize_stage01_casebank_view(casebank_view)
summary = struct();
summary.total_count = casebank_view.meta.total_count;
summary.nominal_count = numel(casebank_view.nominal);
summary.heading_count = numel(casebank_view.heading);
summary.critical_count = numel(casebank_view.critical);
end
