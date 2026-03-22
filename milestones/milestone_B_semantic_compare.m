function result = milestone_B_semantic_compare(cfg)
%MILESTONE_B_SEMANTIC_COMPARE Unified MB semantic-comparison entry point.

mb_safe_startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
apply_plot_runtime_config(cfg);

incoming_meta = cfg.milestones.MB_semantic_compare;
profile_name = local_getfield_or(incoming_meta, 'search_profile', 'mb_default');
if logical(local_getfield_or(incoming_meta, 'search_profile_applied', false))
    resolved_profile = resolve_mb_search_profile(profile_name, cfg);
else
    runtime_overrides = local_extract_runtime_overrides(incoming_meta);
    [cfg, resolved_profile] = apply_mb_search_profile_to_cfg(cfg, profile_name);
    cfg.milestones.MB_semantic_compare = milestone_common_merge_structs(cfg.milestones.MB_semantic_compare, runtime_overrides);
    cfg = local_refresh_domain_state(cfg, resolved_profile);
end
cfg.milestones.MB_semantic_compare.resolved_search_profile = string(resolved_profile.name);
cfg.milestones.MB_semantic_compare.resolved_search_profile_description = string(resolved_profile.description);
meta = cfg.milestones.MB_semantic_compare;
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
paths.summary_report = fullfile(paths.tables, 'MB_run_manifest.md');
paths.summary_mat = fullfile(paths.tables, 'MB_semantic_compare_summary.mat');
paths.cache_key_audit_csv = fullfile(paths.tables, 'cache_key_audit_summary.csv');

resolved_modes = mb_modes(local_getfield_or(meta, 'mode', 'comparison'));
resolved_sensor_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'}));
resolved_families = local_resolve_family_set(local_getfield_or(meta, 'family_set', {'nominal'}));
resolved_heights = reshape(local_getfield_or(meta, 'heights_to_run', 1000), 1, []);

sensor_manifest = local_build_sensor_manifest(resolved_sensor_groups);
run_manifest = local_build_planned_run_manifest(resolved_modes, resolved_sensor_groups, resolved_families, resolved_heights);
sensor_manifest_csv = fullfile(paths.tables, 'MB_sensor_group_manifest.csv');
run_manifest_csv = fullfile(paths.tables, 'MB_run_manifest.csv');
milestone_common_save_table(sensor_manifest, sensor_manifest_csv);
milestone_common_save_table(run_manifest, run_manifest_csv);
milestone_common_save_table(build_mb_cache_key_audit_summary(), paths.cache_key_audit_csv);
local_write_run_manifest(paths.summary_report, resolved_modes, resolved_sensor_groups, resolved_families, resolved_heights, meta);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Unified semantic-comparison shell for MB legacyDG, closedD, and gap-comparison runs.';
result.reused_modules = { ...
    'Stage05-semantic wrapper for legacyDG', ...
    'Stage09-semantic wrapper for closedD', ...
    'MB semantic mode registry', ...
    'Sensor parameter group manager'};
result.tables = struct( ...
    'sensor_group_manifest', string(sensor_manifest_csv), ...
    'run_manifest', string(run_manifest_csv), ...
    'cache_key_audit_summary', string(paths.cache_key_audit_csv));
result.figures = struct();
result.artifacts = struct( ...
    'summary_report', string(paths.summary_report), ...
    'summary_mat', string(paths.summary_mat), ...
    'cache_dir', string(paths.cache));
result.summary = struct( ...
    'search_profile', string(local_getfield_or(meta, 'search_profile', 'mb_default')), ...
    'resolved_search_profile', string(local_getfield_or(meta, 'resolved_search_profile', 'mb_default')), ...
    'search_profile_mode', string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
    'search_profile_mode_description', string(local_getfield_or(meta, 'search_profile_mode_description', "")), ...
    'search_domain_label', string(local_getfield_or(meta, 'search_domain_label', "")), ...
    'plot_domain_label', string(local_getfield_or(meta, 'plot_domain_label', "")), ...
    'cache_policy', string(local_getfield_or(meta, 'cache_policy', 'all_reuse')), ...
    'cache_policy_label', string(format_mb_cache_policy_label(local_getfield_or(meta, 'cache_policy', 'all_reuse'), local_getfield_or(meta, 'cache_profile', struct()), "short")), ...
    'parallel_policy', string(local_getfield_or(resolve_mb_parallel_policy(meta), 'name', "off")), ...
    'parallel_policy_label', string(format_mb_parallel_policy_label(meta, "short")), ...
    'incremental_expansion_policy', string(format_mb_incremental_policy_label(meta, "short")), ...
    'boundary_diagnostics_enabled', logical(local_getfield_or(meta, 'boundary_diagnostics_enabled', true)), ...
    'mode', string(local_getfield_or(meta, 'mode', 'comparison')), ...
    'resolved_modes', {cellstr(string({resolved_modes.name}))}, ...
    'sensor_groups', {resolved_sensor_groups}, ...
    'families', {resolved_families}, ...
    'heights_to_run', resolved_heights, ...
    'dry_run', logical(local_getfield_or(meta, 'dry_run', false)), ...
    'fast_mode', logical(local_getfield_or(meta, 'fast_mode', false)), ...
    'resume_checkpoint', logical(local_getfield_or(meta, 'resume_checkpoint', false)), ...
    'stage05_replica_flag', logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false)), ...
    'strict_replica_lock', logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false)), ...
    'auto_tuned_flag', logical(local_getfield_or(meta, 'auto_tuned_flag', false)), ...
    'run_dense_local', logical(local_getfield_or(meta, 'run_dense_local', false)), ...
    'baseline_validation_only', isequal(resolved_sensor_groups, {'baseline'}));

if logical(local_getfield_or(meta, 'dry_run', false))
    search_domain_audit = build_mb_search_domain_audit_table(meta, repmat(struct(), 0, 1));
    search_domain_audit_csv = fullfile(paths.tables, 'mb_search_domain_audit.csv');
    milestone_common_save_table(search_domain_audit, search_domain_audit_csv);
    result.tables.search_domain_audit = string(search_domain_audit_csv);
    result.summary.execution_status = "dry-run";
    files = milestone_common_export_summary(result, paths);
    result.artifacts.summary_report = files.report_md;
    result.artifacts.summary_mat = files.summary_mat;
    return;
end

run_outputs = local_execute_semantic_runs(cfg, meta, resolved_modes, resolved_sensor_groups, resolved_families, resolved_heights);
result.artifacts.run_outputs = run_outputs;
batch_summary = local_build_sensor_group_batch_summary(run_outputs);
if ~isempty(batch_summary)
    batch_summary_csv = fullfile(paths.tables, 'MB_sensor_group_batch_summary.csv');
    milestone_common_save_table(batch_summary, batch_summary_csv);
    result.tables.sensor_group_batch_summary = string(batch_summary_csv);
end
sensitivity_artifacts = local_export_sensor_group_sensitivity(cfg, meta, run_outputs);
if isfield(sensitivity_artifacts, 'csv') && strlength(sensitivity_artifacts.csv) > 0
    result.tables.sensor_group_sensitivity_check = sensitivity_artifacts.csv;
end
if isfield(sensitivity_artifacts, 'summary')
    result.summary.sensor_group_sensitivity = sensitivity_artifacts.summary;
end
for idx = 1:numel(run_outputs)
    tables_field = local_mode_tables_field(run_outputs(idx).mode, run_outputs(idx).sensor_group);
    figures_field = local_mode_figures_field(run_outputs(idx).mode, run_outputs(idx).sensor_group);
    if isfield(run_outputs(idx), 'artifacts') && isfield(run_outputs(idx).artifacts, 'tables')
        result.tables.(tables_field) = run_outputs(idx).artifacts.tables;
    end
    if isfield(run_outputs(idx), 'artifacts') && isfield(run_outputs(idx).artifacts, 'figures')
        result.figures.(figures_field) = run_outputs(idx).artifacts.figures;
    end
end
comparison_artifacts = local_export_comparison_outputs(cfg, meta, resolved_modes, resolved_sensor_groups, run_outputs);
if ~isempty(fieldnames(comparison_artifacts.tables))
    result.tables.comparison = comparison_artifacts.tables;
end
if ~isempty(fieldnames(comparison_artifacts.figures))
    result.figures.comparison = comparison_artifacts.figures;
end
if isfield(comparison_artifacts, 'summary_table') && ~isempty(comparison_artifacts.summary_table)
    comparison_summary_csv = fullfile(paths.tables, 'MB_comparison_gap_summary_batch.csv');
    milestone_common_save_table(comparison_artifacts.summary_table, comparison_summary_csv);
    result.tables.comparison_batch_summary = string(comparison_summary_csv);
end
if isfield(comparison_artifacts, 'summary')
    result.summary.comparison = comparison_artifacts.summary;
end
control_artifacts = local_export_control_outputs(cfg, meta, run_outputs);
if ~isempty(fieldnames(control_artifacts.tables))
    result.tables.control = control_artifacts.tables;
end
if ~isempty(fieldnames(control_artifacts.figures))
    result.figures.control = control_artifacts.figures;
end
cross_profile_artifacts = local_export_cross_profile_outputs(cfg, meta, run_outputs);
if ~isempty(fieldnames(cross_profile_artifacts.tables))
    result.tables.cross_profile = cross_profile_artifacts.tables;
end
if ~isempty(fieldnames(cross_profile_artifacts.figures))
    result.figures.cross_profile = cross_profile_artifacts.figures;
end
if isfield(cross_profile_artifacts, 'summary_table') && ~isempty(cross_profile_artifacts.summary_table)
    result.tables.cross_profile_summary = string(fullfile(paths.tables, 'MB_profileCompare_summary.csv'));
end
if isfield(cross_profile_artifacts, 'summary')
    result.summary.cross_profile = cross_profile_artifacts.summary;
end
reliability_artifacts = local_export_reliability_reports(paths, run_outputs, comparison_artifacts);
if ~isempty(fieldnames(reliability_artifacts))
    result.tables.reliability = reliability_artifacts;
end
strict_replica_artifacts = local_export_strict_replica_validation_outputs(cfg, meta, run_outputs);
if ~isempty(fieldnames(strict_replica_artifacts.tables))
    result.tables.strict_replica = strict_replica_artifacts.tables;
end
dense_local_artifacts = local_export_dense_local_outputs(cfg, meta, resolved_sensor_groups, resolved_families);
if ~isempty(fieldnames(dense_local_artifacts.tables))
    result.tables.dense_local = dense_local_artifacts.tables;
end
if ~isempty(fieldnames(dense_local_artifacts.figures))
    result.figures.dense_local = dense_local_artifacts.figures;
end
if isfield(dense_local_artifacts, 'summary')
    result.summary.dense_local = dense_local_artifacts.summary;
end
runtime_manifest = local_build_runtime_run_manifest(run_outputs, comparison_artifacts, meta, paths);
if ~isempty(runtime_manifest)
    milestone_common_save_table(runtime_manifest, run_manifest_csv);
end
cache_summary_artifacts = local_export_cache_runtime_summaries(paths, run_outputs, meta);
if isfield(cache_summary_artifacts, 'reuse_csv') && strlength(cache_summary_artifacts.reuse_csv) > 0
    result.tables.cache_reuse_decision_summary = cache_summary_artifacts.reuse_csv;
end
if isfield(cache_summary_artifacts, 'signature_csv') && strlength(cache_summary_artifacts.signature_csv) > 0
    result.tables.cache_signature_manifest = cache_summary_artifacts.signature_csv;
end
result.summary.execution_status = "executed";
result.summary.run_count = numel(run_outputs);

metadata_artifacts = finalize_mb_output_metadata(paths, struct( ...
    'meta', meta, ...
    'run_outputs', run_outputs, ...
    'artifact_files', {local_collect_result_artifact_files(result)}, ...
    'resolved_modes', {resolved_modes}, ...
    'resolved_sensor_groups', {resolved_sensor_groups}, ...
    'resolved_families', {resolved_families}, ...
    'resolved_heights', resolved_heights));
if isfield(metadata_artifacts, 'manifest_csv') && strlength(metadata_artifacts.manifest_csv) > 0
    result.tables.output_metadata_manifest = metadata_artifacts.manifest_csv;
end
if isfield(metadata_artifacts, 'autotune_csv') && strlength(metadata_artifacts.autotune_csv) > 0
    result.tables.autotune_summary = metadata_artifacts.autotune_csv;
end
search_domain_audit = build_mb_search_domain_audit_table(meta, run_outputs);
search_domain_audit_csv = fullfile(paths.tables, 'mb_search_domain_audit.csv');
milestone_common_save_table(search_domain_audit, search_domain_audit_csv);
result.tables.search_domain_audit = string(search_domain_audit_csv);
result.summary.output_metadata_manifest_rows = local_getfield_or(metadata_artifacts, 'manifest_row_count', 0);

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function files = local_collect_result_artifact_files(result)
files = strings(0, 1);
files = local_collect_artifact_paths_iterative(files, local_getfield_or(result, 'tables', struct()));
files = local_collect_artifact_paths_iterative(files, local_getfield_or(result, 'figures', struct()));
files = local_collect_artifact_paths_iterative(files, local_getfield_or(result, 'artifacts', struct()));
files = unique(files(strlength(files) > 0));
end

function files = local_collect_artifact_paths_iterative(files, value)
stack = {value};
while ~isempty(stack)
    current = stack{end};
    stack(end) = [];
    if isstring(current) || ischar(current)
        candidate = string(current);
        candidate = candidate(:);
        for idx_candidate = 1:numel(candidate)
            current_candidate = candidate(idx_candidate);
            if strlength(current_candidate) > 0 && local_is_supported_artifact(current_candidate)
                files(end + 1, 1) = current_candidate; %#ok<AGROW>
            end
        end
        continue;
    end
    if iscell(current)
        for idx = numel(current):-1:1
            stack{end + 1} = current{idx}; %#ok<AGROW>
        end
        continue;
    end
    if isstruct(current)
        if isempty(current)
            continue;
        end
        if numel(current) > 1
            for idx = numel(current):-1:1
                stack{end + 1} = current(idx); %#ok<AGROW>
            end
            continue;
        end
        names = fieldnames(current);
        for idx = numel(names):-1:1
            stack{end + 1} = current.(names{idx}); %#ok<AGROW>
        end
    end
end
end

function tf = local_is_supported_artifact(path_value)
[~, ~, ext] = fileparts(char(path_value));
tf = any(strcmpi(ext, {'.csv', '.png', '.md', '.txt'}));
end

function outputs = local_execute_semantic_runs(cfg, meta, resolved_modes, sensor_groups, family_set, heights_to_run)
need_legacy = any(arrayfun(@(m) logical(m.uses_legacydg), resolved_modes));
need_closed = any(arrayfun(@(m) logical(m.uses_closedd), resolved_modes));
plot_options = local_semantic_plot_options(meta);
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
parallel_policy = resolve_mb_parallel_policy(meta);
tasks = local_build_semantic_tasks(sensor_groups, heights_to_run, family_set, need_legacy, need_closed);
task_runner = @(task) local_execute_semantic_task(cfg, meta, task, parallel_policy);
if logical(parallel_policy.outer_enabled)
    task_outputs = run_mb_task_bundle_parallel(tasks, task_runner, parallel_policy);
else
    task_outputs = run_mb_task_bundle_parallel(tasks, task_runner, resolve_mb_parallel_policy(struct('parallel_policy', 'off')));
end
outputs = local_merge_semantic_task_outputs(task_outputs);
for idx = 1:numel(outputs)
    if outputs(idx).mode == "legacyDG"
        outputs(idx).artifacts = export_mb_legacydg_outputs(outputs(idx).run_output, paths, plot_options);
    else
        outputs(idx).artifacts = export_mb_closedd_outputs(outputs(idx).run_output, paths, plot_options);
    end
end
end

function tasks = local_build_semantic_tasks(sensor_groups, heights_to_run, family_set, need_legacy, need_closed)
tasks = repmat(struct('mode', "", 'sensor_group', "", 'height_km', NaN, 'family_set', {{}}, 'strict_replica', false), 0, 1);
for idx_group = 1:numel(sensor_groups)
    sensor_group = sensor_groups{idx_group};
    for idx_h = 1:numel(heights_to_run)
        h_km = heights_to_run(idx_h);
        if need_legacy
            tasks(end + 1, 1) = struct( ... %#ok<AGROW>
                'mode', "legacyDG", ...
                'sensor_group', string(sensor_group), ...
                'height_km', h_km, ...
                'family_set', {family_set}, ...
                'strict_replica', strcmpi(sensor_group, 'stage05_strict_reference'));
        end
        if need_closed
            tasks(end + 1, 1) = struct( ... %#ok<AGROW>
                'mode', "closedD", ...
                'sensor_group', string(sensor_group), ...
                'height_km', h_km, ...
                'family_set', {family_set}, ...
                'strict_replica', false);
        end
    end
end
end

function task_output = local_execute_semantic_task(cfg, meta, task, parallel_policy)
common_options = struct( ...
    'sensor_group', char(task.sensor_group), ...
    'heights_to_run', task.height_km, ...
    'family_set', {task.family_set}, ...
    'i_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
    'P_grid', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
    'T_grid', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
    'F_fixed', local_getfield_or(meta, 'F_fixed', 1), ...
    'parallel_policy', parallel_policy, ...
    'use_parallel', local_resolve_task_use_parallel(meta, parallel_policy));

if task.mode == "legacyDG"
        if logical(local_getfield_or(meta.stage05_replica, 'strict', false)) && logical(task.strict_replica)
            strict_options = common_options;
            strict_options.build_validation_summary = true;
            strict_output = run_mb_stage05_strict_replica(cfg, strict_options);
            legacy_output = strict_output.legacy_output;
            legacy_output.validation_summary = strict_output.validation_summary;
            legacy_output.validation_meta = strict_output.validation_meta;
            legacy_output.validation_manifest_struct = strict_output.validation_manifest_struct;
            legacy_output.validation_manifest_table = strict_output.validation_manifest_table;
            legacy_output.strict_replica = strict_output;
            run_output = legacy_output;
        else
            run_output = run_mb_legacydg_semantics(cfg, common_options);
        end
else
    run_output = run_mb_closedd_semantics(cfg, common_options);
end

task_output = struct( ...
    'mode', task.mode, ...
    'sensor_group', string(task.sensor_group), ...
    'run_output', run_output, ...
    'artifacts', struct());
end

function outputs = local_merge_semantic_task_outputs(task_outputs)
if isempty(task_outputs)
    outputs = repmat(struct('mode', "", 'sensor_group', "", 'run_output', struct(), 'artifacts', struct()), 0, 1);
    return;
end

group_keys = strings(numel(task_outputs), 1);
for idx = 1:numel(task_outputs)
    group_keys(idx) = task_outputs(idx).mode + "|" + task_outputs(idx).sensor_group;
end
unique_keys = unique(group_keys, 'stable');
outputs = repmat(struct('mode', "", 'sensor_group', "", 'run_output', struct(), 'artifacts', struct()), numel(unique_keys), 1);
for idx_key = 1:numel(unique_keys)
    member_idx = find(group_keys == unique_keys(idx_key));
    group_runs = task_outputs(member_idx);
    merged = group_runs(1).run_output;
    for idx_member = 2:numel(group_runs)
        merged = local_merge_run_outputs(merged, group_runs(idx_member).run_output);
    end
    outputs(idx_key, 1) = struct( ...
        'mode', group_runs(1).mode, ...
        'sensor_group', group_runs(1).sensor_group, ...
        'run_output', merged, ...
        'artifacts', struct());
end
end

function merged = local_merge_run_outputs(base_output, added_output)
merged = base_output;
merged.runs = [base_output.runs; added_output.runs];
if numel(merged.runs) > 1
    [~, order] = sort([merged.runs.h_km]);
    merged.runs = merged.runs(order);
end
if isfield(base_output, 'cache_records') || isfield(added_output, 'cache_records')
    merged.cache_records = [local_getfield_or(base_output, 'cache_records', repmat(struct(), 0, 1)); ...
        local_getfield_or(added_output, 'cache_records', repmat(struct(), 0, 1))];
end
merged.options.heights_to_run = unique([reshape(local_getfield_or(base_output.options, 'heights_to_run', []), 1, []), ...
    reshape(local_getfield_or(added_output.options, 'heights_to_run', []), 1, [])], 'stable');
if isfield(merged, 'summary')
    merged.summary.total_run_count = numel(merged.runs);
    merged.summary.cache_hits = local_getfield_or(base_output.summary, 'cache_hits', 0) + local_getfield_or(added_output.summary, 'cache_hits', 0);
    merged.summary.fresh_evaluations = local_getfield_or(base_output.summary, 'fresh_evaluations', 0) + local_getfield_or(added_output.summary, 'fresh_evaluations', 0);
    merged.summary.heights_to_run = merged.options.heights_to_run;
end
end

function use_parallel = local_resolve_task_use_parallel(meta, parallel_policy)
if logical(parallel_policy.outer_enabled) || logical(parallel_policy.inner_enabled)
    use_parallel = false;
else
    use_parallel = logical(local_getfield_or(meta, 'use_parallel', true));
end
end

function plot_options = local_semantic_plot_options(meta)
plot_options = struct();
if isfield(meta, 'plot_xlim_ns')
    plot_options.plot_xlim_ns = meta.plot_xlim_ns;
end
if isfield(meta, 'plot_ylim_passratio')
    plot_options.plot_ylim_passratio = meta.plot_ylim_passratio;
end
plot_options.plot_domain_source = local_resolve_plot_domain_source(meta);
plot_options.search_domain_label = string(local_getfield_or(meta, 'search_domain_label', ""));
plot_options.plot_domain_label = string(local_getfield_or(meta, 'plot_domain_label', ""));
plot_options.domain_summary = sprintf('search-domain: %s', char(string(local_getfield_or(meta, 'search_domain_label', ""))));
plot_options.figure_style = resolve_mb_figure_style_mode(local_getfield_or(meta, 'figure_style_mode', 'diagnostic'));
plot_options.figure_style_mode = string(plot_options.figure_style.name);
plot_options.export_paper_ready = logical(local_getfield_or(meta, 'export_paper_ready', false));
plot_options.paper_ready_guardrail = local_getfield_or(meta, 'paper_ready_guardrail', struct());
diagnostic_text = local_resolve_autotune_diagnostic(meta);
if strlength(diagnostic_text) > 0
    plot_options.diagnostic_text = diagnostic_text;
end
end

function manifest = local_build_sensor_manifest(sensor_groups)
manifest = table('Size', [numel(sensor_groups), 6], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'string', 'string'}, ...
    'VariableNames', {'sensor_group', 'max_off_boresight_deg', 'angle_resolution_arcsec', 'angle_resolution_rad', 'sensor_label', 'description'});
for idx = 1:numel(sensor_groups)
    group = get_sensor_param_group(sensor_groups{idx});
    manifest(idx, :) = { ...
        string(group.name), ...
        group.max_off_boresight_deg, ...
        group.angle_resolution_arcsec, ...
        group.angle_resolution_rad, ...
        string(group.sensor_label), ...
        string(group.description)};
end
end

function manifest = local_build_planned_run_manifest(resolved_modes, sensor_groups, family_set, heights_to_run)
row_count = numel(resolved_modes) * numel(sensor_groups) * numel(family_set) * numel(heights_to_run);
manifest = table('Size', [row_count, 8], ...
    'VariableTypes', {'string', 'string', 'double', 'string', 'logical', 'logical', 'logical', 'string'}, ...
    'VariableNames', {'mode', 'sensor_group', 'h_km', 'family_name', 'uses_legacydg', 'uses_closedd', 'emits_gap_outputs', 'output_tag'});
cursor = 0;
for idx_mode = 1:numel(resolved_modes)
    mode_entry = resolved_modes(idx_mode);
    for idx_group = 1:numel(sensor_groups)
        for idx_family = 1:numel(family_set)
            for idx_h = 1:numel(heights_to_run)
                cursor = cursor + 1;
                manifest(cursor, :) = { ...
                    string(mode_entry.name), ...
                    string(sensor_groups{idx_group}), ...
                    heights_to_run(idx_h), ...
                    string(family_set{idx_family}), ...
                    logical(mode_entry.uses_legacydg), ...
                    logical(mode_entry.uses_closedd), ...
                    logical(mode_entry.emits_gap_outputs), ...
                    string(mode_entry.output_tag)};
            end
        end
    end
end
manifest = manifest(1:cursor, :);
end

function local_write_run_manifest(file_path, resolved_modes, sensor_groups, family_set, heights_to_run, meta)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open MB run manifest: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid));

fprintf(fid, '# MB Semantic Compare Run Manifest\n\n');
fprintf(fid, '- `mode`: %s\n', char(string(local_getfield_or(meta, 'mode', 'comparison'))));
fprintf(fid, '- `search_profile`: %s\n', char(string(local_getfield_or(meta, 'resolved_search_profile', 'mb_default'))));
fprintf(fid, '- `profile_mode`: %s\n', char(format_mb_search_profile_mode_label(local_getfield_or(meta, 'search_profile_mode', 'debug'), "short")));
fprintf(fid, '- `search_domain`: %s\n', char(string(local_getfield_or(meta, 'search_domain_label', ""))));
fprintf(fid, '- `plot_domain`: %s\n', char(string(local_getfield_or(meta, 'plot_domain_label', ""))));
fprintf(fid, '- `cache_policy`: %s\n', char(format_mb_cache_policy_label(local_getfield_or(meta, 'cache_policy', 'all_reuse'), local_getfield_or(meta, 'cache_profile', struct()), "detailed")));
fprintf(fid, '- `cache_signature_seed`: %s\n', char(build_mb_cache_signature(struct( ...
    'semantic_name', string(local_getfield_or(meta, 'mode', 'comparison')), ...
    'sensor_group', string(strjoin(resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'})), ',')), ...
    'search_profile_name', string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default'))), ...
    'search_profile_mode', string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
    'height_km', local_getfield_or(meta, 'heights_to_run', NaN), ...
    'family_name', string(strjoin(local_resolve_family_set(local_getfield_or(meta, 'family_set', {'nominal'})), ',')), ...
    'Ns_grid', local_getfield_or(meta, 'Ns_initial_range', []), ...
    'P_grid', local_getfield_or(meta, 'P_grid', []), ...
    'T_grid', local_getfield_or(meta, 'T_grid', []), ...
    'expand_blocks', local_getfield_or(meta, 'Ns_expand_blocks', []), ...
    'Ns_hard_max', local_getfield_or(meta, 'Ns_hard_max', NaN)))));
fprintf(fid, '- `incremental_policy`: %s\n', char(format_mb_incremental_policy_label(meta, "detailed")));
fprintf(fid, '- `parallel_policy`: %s\n', char(format_mb_parallel_policy_label(meta, "detailed")));
fprintf(fid, '- `boundary_diagnostics`: %s\n', char(format_mb_boundary_diagnostics_label(local_getfield_or(meta, 'boundary_diagnostics_enabled', true), "detailed")));
fprintf(fid, '- `sensor_groups`: %s\n', strjoin(sensor_groups, ', '));
fprintf(fid, '- `families`: %s\n', strjoin(family_set, ', '));
fprintf(fid, '- `heights_to_run_km`: %s\n', mat2str(heights_to_run));
fprintf(fid, '- `dry_run`: %s\n', char(string(logical(local_getfield_or(meta, 'dry_run', false)))));
fprintf(fid, '- `fast_mode`: %s\n', char(string(logical(local_getfield_or(meta, 'fast_mode', false)))));
fprintf(fid, '- `auto_tuned_flag`: %s\n', char(string(logical(local_getfield_or(meta, 'auto_tuned_flag', false)))));
fprintf(fid, '- `stage05_replica_flag`: %s\n', char(string(logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false)))));
fprintf(fid, '- `strict_replica_lock`: %s\n', char(string(logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false)))));
fprintf(fid, '- `plot_xlim_ns`: %s\n', local_stringify_manifest_value(local_getfield_or(meta, 'plot_xlim_ns', [])));
fprintf(fid, '- `run_dense_local`: %s\n\n', char(string(logical(local_getfield_or(meta, 'run_dense_local', false)))));

fprintf(fid, '## Modes\n\n');
for idx = 1:numel(resolved_modes)
    mode_entry = resolved_modes(idx);
    fprintf(fid, '- `%s`: %s\n', mode_entry.name, mode_entry.description);
end
end

function search_domain = local_build_runtime_search_domain(run_output, run)
search_domain = struct( ...
    'ns_search_min', local_getfield_or(run_output.options, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'ns_search_max', local_getfield_or(run_output.options, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')), ...
    'ns_search_step', local_min_spacing(run.design_table, 'Ns'), ...
    'P_grid', unique(run.design_table.P, 'sorted'), ...
    'T_grid', unique(run.design_table.T, 'sorted'));
end

function stop_reason = local_incremental_stop_reason(run)
history = local_getfield_or(run, 'incremental_search_history', table());
if isempty(history) || height(history) == 0 || ~ismember('stop_reason', history.Properties.VariableNames)
    stop_reason = "no_history";
else
    stop_reason = string(history.stop_reason(end));
end
end

function flag = local_diag_flag(T, field_name)
flag = false;
if isempty(T) || ~istable(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
values = T.(field_name);
if islogical(values)
    flag = any(values);
else
    flag = any(logical(values));
end
end

function value = local_table_value(T, field_name, idx, fallback)
if isempty(T) || ~istable(T) || ~ismember(field_name, T.Properties.VariableNames) || idx > height(T)
    value = fallback;
    return;
end
column = T.(field_name);
value = column(idx);
if ismissing(value)
    value = fallback;
end
end

function value = local_min_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_max_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = local_min_spacing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = unique(sort(T.(field_name)));
values = values(isfinite(values));
if numel(values) < 2
    value = NaN;
else
    value = min(diff(values));
end
end

function manifest = local_build_runtime_run_manifest(run_outputs, comparison_artifacts, meta, paths)
rows = cell(0, 1);
search_domain_label = string(local_getfield_or(meta, 'search_domain_label', ""));
plot_domain_label = string(local_getfield_or(meta, 'plot_domain_label', ""));
cache_policy_label = string(format_mb_cache_policy_label(local_getfield_or(meta, 'cache_policy', 'all_reuse'), local_getfield_or(meta, 'cache_profile', struct()), "short"));
parallel_policy_label = string(format_mb_parallel_policy_label(meta, "short"));
incremental_policy_label = string(format_mb_incremental_policy_label(meta, "short"));
strict_lock = logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false));
boundary_enabled = logical(local_getfield_or(meta, 'boundary_diagnostics_enabled', true));
cache_strict = logical(local_getfield_or(local_getfield_or(meta, 'cache_profile', struct()), 'strict_compatibility', true));
run_timestamp = string(datestr(now, 'yyyy-mm-dd HH:MM:SS'));

for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    for idx_run = 1:numel(run_output.runs)
        run = run_output.runs(idx_run);
        search_domain = local_build_runtime_search_domain(run_output, run);
        passratio_diag = build_mb_passratio_saturation_diagnostics(run.aggregate.passratio_phasecurve, search_domain, struct( ...
            'value_fields', {{'max_pass_ratio'}}, ...
            'semantic_labels', {{char(run_outputs(idx).mode)}}, ...
            'h_km', run.h_km, ...
            'family_name', string(run.family_name)));
        boundary_diag = build_mb_boundary_hit_table(run.aggregate.requirement_surface_iP.surface_table, search_domain, struct( ...
            'value_fields', {{'minimum_feasible_Ns'}}, ...
            'semantic_labels', {{char(run_outputs(idx).mode)}}, ...
            'h_km', run.h_km, ...
            'family_name', string(run.family_name)));
        cache_signature = local_build_runtime_cache_signature(meta, run_outputs(idx).mode, run_output.sensor_group.name, run, search_domain);
        stop_reason = local_incremental_stop_reason(run);
        boundary_dominated = local_diag_flag(boundary_diag, 'is_boundary_dominated');
        unity_reached = local_diag_flag(passratio_diag, 'right_unity_reached');
        rows{end + 1, 1} = { ... %#ok<AGROW>
            run_timestamp, ...
            "semantic", ...
            string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default'))), ...
            string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
            string(run_output.sensor_group.name), ...
            run.h_km, ...
            string(run_outputs(idx).mode), ...
            string(run.family_name), ...
            search_domain_label, ...
            plot_domain_label, ...
            cache_policy_label, ...
            cache_strict, ...
            parallel_policy_label, ...
            incremental_policy_label, ...
            boundary_enabled, ...
            strict_lock, ...
            string(cache_signature), ...
            string(stop_reason), ...
            boundary_dominated, ...
            unity_reached, ...
            string(paths.tables)};
    end
end

if isfield(comparison_artifacts, 'summary_table') && istable(comparison_artifacts.summary_table) && ~isempty(comparison_artifacts.summary_table)
    summary_table = comparison_artifacts.summary_table;
    for idx = 1:height(summary_table)
        stop_reason = local_table_value(summary_table, 'frontier_status_note', idx, "");
        boundary_dominated = logical(local_table_value(summary_table, 'boundary_dominated_result', idx, false));
        unity_reached = logical(local_table_value(summary_table, 'right_plateau_reached_legacy', idx, false) && ...
            local_table_value(summary_table, 'right_plateau_reached_closed', idx, false));
        comparison_domain = struct( ...
            'ns_search_min', NaN, ...
            'ns_search_max', NaN, ...
            'ns_search_step', NaN, ...
            'P_grid', [], ...
            'T_grid', []);
        cache_signature = build_mb_cache_signature(struct( ...
            'semantic_name', "comparison", ...
            'sensor_group', string(local_table_value(summary_table, 'sensor_group', idx, "")), ...
            'search_profile_name', string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default'))), ...
            'search_profile_mode', string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
            'height_km', local_table_value(summary_table, 'h_km', idx, NaN), ...
            'family_name', string(local_table_value(summary_table, 'family_name', idx, "")), ...
            'Ns_grid', [local_getfield_or(comparison_domain, 'ns_search_min', NaN), local_getfield_or(comparison_domain, 'ns_search_max', NaN), local_getfield_or(comparison_domain, 'ns_search_step', NaN)], ...
            'P_grid', local_getfield_or(comparison_domain, 'P_grid', []), ...
            'T_grid', local_getfield_or(comparison_domain, 'T_grid', []), ...
            'expand_blocks', local_getfield_or(meta, 'Ns_expand_blocks', []), ...
            'Ns_hard_max', local_getfield_or(meta, 'Ns_hard_max', NaN)));
        rows{end + 1, 1} = { ... %#ok<AGROW>
            run_timestamp, ...
            "comparison", ...
            string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default'))), ...
            string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
            string(local_table_value(summary_table, 'sensor_group', idx, "")), ...
            local_table_value(summary_table, 'h_km', idx, NaN), ...
            "comparison", ...
            string(local_table_value(summary_table, 'family_name', idx, "")), ...
            search_domain_label, ...
            plot_domain_label, ...
            cache_policy_label, ...
            cache_strict, ...
            parallel_policy_label, ...
            incremental_policy_label, ...
            boundary_enabled, ...
            strict_lock, ...
            string(cache_signature), ...
            string(stop_reason), ...
            boundary_dominated, ...
            unity_reached, ...
            string(paths.tables)};
    end
end

if isempty(rows)
    manifest = table();
    return;
end

manifest = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'run_timestamp', 'row_kind', 'profile_name', 'profile_mode', 'sensor_group', 'height_km', ...
    'semantic_mode', 'family_name', 'search_domain', 'plot_domain', 'cache_policy', ...
    'cache_strict_compatibility', 'parallel_policy', 'incremental_expansion_policy', ...
    'boundary_diagnostics_enabled', 'strict_replica_lock', 'cache_signature', 'stop_reason', ...
    'boundary_dominated', 'unity_plateau_reached', 'output_folder'});
end

function cache_signature = local_build_runtime_cache_signature(meta, semantic_mode, sensor_group_name, run, search_domain)
cache_signature = build_mb_cache_signature(struct( ...
    'semantic_name', string(semantic_mode), ...
    'sensor_group', string(sensor_group_name), ...
    'search_profile_name', string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default'))), ...
    'search_profile_mode', string(local_getfield_or(meta, 'search_profile_mode', 'debug')), ...
    'height_km', local_getfield_or(run, 'h_km', NaN), ...
    'family_name', string(local_getfield_or(run, 'family_name', "")), ...
    'Ns_grid', [local_getfield_or(search_domain, 'ns_search_min', NaN), local_getfield_or(search_domain, 'ns_search_max', NaN), local_getfield_or(search_domain, 'ns_search_step', NaN)], ...
    'P_grid', reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []), ...
    'T_grid', reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []), ...
    'expand_blocks', local_getfield_or(meta, 'Ns_expand_blocks', []), ...
    'Ns_hard_max', local_getfield_or(meta, 'Ns_hard_max', NaN)));
end

function family_set = local_resolve_family_set(family_input)
tokens = cellstr(string(family_input));
tokens = cellfun(@(s) lower(strtrim(s)), tokens, 'UniformOutput', false);
if any(strcmp(tokens, 'all'))
    family_set = {'nominal', 'heading', 'critical'};
else
    family_set = unique(tokens, 'stable');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function source = local_resolve_plot_domain_source(meta)
plot_domain = local_getfield_or(meta, 'plot_domain', struct());
if isstruct(plot_domain) && isfield(plot_domain, 'plot_xlim_mode') && strlength(string(plot_domain.plot_xlim_mode)) > 0
    source = string(plot_domain.plot_xlim_mode);
elseif logical(local_getfield_or(meta, 'auto_tuned_flag', false))
    source = "autotuned_profile";
elseif logical(local_getfield_or(local_getfield_or(meta, 'auto_tune', struct()), 'enabled', false))
    source = "search_profile_with_autotune_probe";
else
    source = "search_profile";
end
end

function diagnostic_text = local_resolve_autotune_diagnostic(meta)
diagnostic_text = "";
auto_tune_result = local_getfield_or(meta, 'auto_tune_result', struct());
if ~isstruct(auto_tune_result) || isempty(fieldnames(auto_tune_result))
    return;
end

state = string(local_getfield_or(auto_tune_result, 'state', ""));
stop_reason = string(local_getfield_or(auto_tune_result, 'final_stop_reason', local_getfield_or(auto_tune_result, 'stop_reason', "")));
if state == "success"
    diagnostic_text = "auto-tune: balanced window";
elseif stop_reason ~= ""
    diagnostic_text = "auto-tune stop: " + stop_reason;
end
end

function txt = local_stringify_manifest_value(value)
if isnumeric(value) || islogical(value)
    if isempty(value)
        txt = '[]';
    elseif isscalar(value)
        txt = char(string(value));
    else
        txt = mat2str(value);
    end
elseif isstring(value) || ischar(value)
    txt = char(string(value));
elseif iscell(value)
    txt = strjoin(cellstr(string(value)), ', ');
else
    txt = char(string(value));
end
end

function overrides = local_extract_runtime_overrides(meta)
allowed = { ...
    'milestone_id', ...
    'title', ...
    'search_profile', ...
    'search_profile_applied', ...
    'search_profile_mode', ...
    'dry_run', ...
    'mode', ...
    'sensor_groups', ...
    'heights_to_run', ...
    'i_grid_deg', ...
    'P_grid', ...
    'T_grid', ...
    'plot_xlim_ns', ...
    'plot_ylim_passratio', ...
    'search_domain', ...
    'plot_domain', ...
    'search_domain_policy', ...
    'plot_domain_policy', ...
    'family_set', ...
    'fast_mode', ...
    'resume_checkpoint', ...
    'use_parallel', ...
    'cache_policy', ...
    'auto_tune', ...
    'cache_profile', ...
    'stage05_replica', ...
    'run_dense_local', ...
    'search_range_source', ...
    'cli_selection'};
overrides = struct();
for idx = 1:numel(allowed)
    field_name = allowed{idx};
    if isfield(meta, field_name)
        overrides.(field_name) = meta.(field_name);
    end
end
end

function cfg = local_refresh_domain_state(cfg, resolved_profile)
meta = cfg.milestones.MB_semantic_compare;
context = local_getfield_or(meta, 'search_profile_context', struct());
if ~isfield(context, 'user_selected_profile_name') || strlength(string(context.user_selected_profile_name)) == 0
    context.user_selected_profile_name = string(local_getfield_or(meta, 'search_profile', local_getfield_or(resolved_profile, 'name', "mb_default")));
end
context.profile_mode = string(local_getfield_or(meta, 'search_profile_mode', local_getfield_or(resolved_profile, 'profile_mode', "debug")));
context.figure_family = string(local_getfield_or(context, 'figure_family', "passratio"));
context.semantic_mode = string(local_getfield_or(meta, 'mode', local_getfield_or(resolved_profile, 'semantic_mode', "comparison")));
sensor_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', local_getfield_or(resolved_profile, 'sensor_group_names', {'baseline'})));
if ~isempty(sensor_groups)
    context.sensor_group = string(sensor_groups{1});
end
heights_to_run = reshape(local_getfield_or(meta, 'heights_to_run', local_getfield_or(resolved_profile, 'height_grid_km', 1000)), 1, []);
if ~isempty(heights_to_run)
    context.height_km = heights_to_run(1);
end

profile = struct( ...
    'name', string(local_getfield_or(meta, 'search_profile', local_getfield_or(resolved_profile, 'name', "mb_default"))), ...
    'profile_mode', string(local_getfield_or(meta, 'search_profile_mode', local_getfield_or(resolved_profile, 'profile_mode', "debug"))), ...
    'semantic_mode', string(local_getfield_or(meta, 'mode', local_getfield_or(resolved_profile, 'semantic_mode', "comparison"))), ...
    'sensor_group_names', {cellstr(string(sensor_groups))}, ...
    'height_grid_km', heights_to_run, ...
    'inclination_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', local_getfield_or(resolved_profile, 'inclination_grid_deg', [])), 1, []), ...
    'P_grid', reshape(local_getfield_or(meta, 'P_grid', local_getfield_or(resolved_profile, 'P_values', [])), 1, []), ...
    'T_grid', reshape(local_getfield_or(meta, 'T_grid', local_getfield_or(resolved_profile, 'T_values', [])), 1, []), ...
    'P_values', reshape(local_getfield_or(meta, 'P_grid', local_getfield_or(resolved_profile, 'P_values', [])), 1, []), ...
    'T_values', reshape(local_getfield_or(meta, 'T_grid', local_getfield_or(resolved_profile, 'T_values', [])), 1, []), ...
    'plot_xlim_ns', reshape(local_getfield_or(meta, 'plot_xlim_ns', local_getfield_or(resolved_profile, 'Ns_xlim_plot', [])), 1, []), ...
    'Ns_xlim_plot', reshape(local_getfield_or(meta, 'plot_xlim_ns', local_getfield_or(resolved_profile, 'Ns_xlim_plot', [])), 1, []), ...
    'plot_ylim_passratio', reshape(local_getfield_or(meta, 'plot_ylim_passratio', local_getfield_or(resolved_profile, 'plot_ylim_passratio', [0, 1.05])), 1, []), ...
    'stage05_replica', local_getfield_or(meta, 'stage05_replica', local_getfield_or(resolved_profile, 'stage05_replica', struct())), ...
    'auto_tune', local_getfield_or(meta, 'auto_tune', local_getfield_or(resolved_profile, 'auto_tune', struct())), ...
    'search_domain', local_getfield_or(meta, 'search_domain', local_getfield_or(resolved_profile, 'search_domain', struct())), ...
    'plot_domain', local_getfield_or(meta, 'plot_domain', local_getfield_or(resolved_profile, 'plot_domain', struct())));

search_domain = resolve_mb_search_domain_for_context(context, cfg, profile);
plot_domain = resolve_mb_plot_domain_for_context(context, cfg, profile, search_domain);
cfg = apply_mb_search_domain_to_cfg(cfg, search_domain);
cfg = apply_mb_plot_domain_to_cfg(cfg, plot_domain);
end

function count = local_count_wrapped_runs(need_legacy, need_closed, sensor_group_count)
count_per_group = double(need_legacy) + double(need_closed);
count = sensor_group_count * count_per_group;
end


function field_name = local_mode_tables_field(mode_name, sensor_group)
field_name = matlab.lang.makeValidName(sprintf('%s_%s_tables', string(mode_name), string(sensor_group)));
end

function field_name = local_mode_figures_field(mode_name, sensor_group)
field_name = matlab.lang.makeValidName(sprintf('%s_%s_figures', string(mode_name), string(sensor_group)));
end

function artifacts = local_export_cache_runtime_summaries(paths, run_outputs, meta)
artifacts = struct('reuse_csv', "", 'signature_csv', "");
reuse_rows = cell(0, 1);
signature_rows = cell(0, 1);

for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    cache_records = local_getfield_or(run_output, 'cache_records', repmat(struct(), 0, 1));
    for idx_record = 1:numel(cache_records)
        record = cache_records(idx_record);
        semantic_mode = string(local_getfield_or(run_outputs(idx), 'mode', ""));
        sensor_group = string(local_getfield_or(run_output.sensor_group, 'name', ""));
        search_profile = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', "mb_default")));
        profile_mode = string(local_getfield_or(meta, 'search_profile_mode', "debug"));
        cache_file = string(local_getfield_or(record, 'cache_file', ""));
        manifest_csv = string(local_getfield_or(record, 'manifest_csv', ""));
        reuse_rows{end + 1, 1} = { ... %#ok<AGROW>
            semantic_mode, ...
            sensor_group, ...
            string(local_getfield_or(record, 'family_name', "")), ...
            double(local_getfield_or(record, 'h_km', NaN)), ...
            logical(local_getfield_or(record, 'cache_hit', false)), ...
            double(local_getfield_or(record, 'cache_hit_count', 0)), ...
            double(local_getfield_or(record, 'fresh_evaluation_count', 0)), ...
            string(local_getfield_or(record, 'reason', "")), ...
            search_profile, ...
            profile_mode, ...
            cache_file, ...
            manifest_csv};

        manifest_info = read_mb_cache_manifest(cache_file);
        manifest = local_getfield_or(manifest_info, 'manifest', struct());
        signature_rows{end + 1, 1} = { ... %#ok<AGROW>
            semantic_mode, ...
            sensor_group, ...
            string(local_getfield_or(record, 'family_name', "")), ...
            double(local_getfield_or(record, 'h_km', NaN)), ...
            string(local_getfield_or(manifest, 'cache_signature', "")), ...
            string(local_getfield_or(manifest, 'semantic_cache_signature', "")), ...
            string(local_getfield_or(manifest, 'figure_cache_signature', "")), ...
            double(local_getfield_or(manifest, 'cache_schema_version', NaN)), ...
            string(local_getfield_or(manifest, 'semantic_version', "")), ...
            string(local_getfield_or(manifest, 'figure_version', "")), ...
            string(local_getfield_or(manifest, 'generator_version', "")), ...
            manifest_csv};
    end
end

if ~isempty(reuse_rows)
    reuse_table = cell2table(vertcat(reuse_rows{:}), 'VariableNames', { ...
        'semantic_mode', 'sensor_group', 'family_name', 'height_km', ...
        'cache_reused', 'cache_hit_count', 'fresh_evaluation_count', 'reuse_decision_reason', ...
        'search_profile_name', 'search_profile_mode', 'cache_file', 'manifest_csv'});
    artifacts.reuse_csv = string(fullfile(paths.tables, 'cache_reuse_decision_summary.csv'));
    milestone_common_save_table(reuse_table, artifacts.reuse_csv);
end

if ~isempty(signature_rows)
    signature_table = cell2table(vertcat(signature_rows{:}), 'VariableNames', { ...
        'semantic_mode', 'sensor_group', 'family_name', 'height_km', ...
        'cache_signature', 'semantic_cache_signature', 'figure_cache_signature', ...
        'cache_schema_version', 'semantic_version', 'figure_version', ...
        'generator_version', 'manifest_csv'});
    artifacts.signature_csv = string(fullfile(paths.tables, 'cache_signature_manifest.csv'));
    milestone_common_save_table(signature_table, artifacts.signature_csv);
end
end

function artifacts = local_export_comparison_outputs(cfg, meta, resolved_modes, sensor_groups, run_outputs)
artifacts = struct('tables', struct(), 'figures', struct(), 'summary', struct(), 'summary_table', table());
if ~any(arrayfun(@(m) logical(m.emits_gap_outputs), resolved_modes))
    return;
end

paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
plot_options = local_semantic_plot_options(meta);
summary_rows = cell(numel(sensor_groups), 1);
summary_cursor = 0;
for idx_group = 1:numel(sensor_groups)
    sensor_group = string(sensor_groups{idx_group});
    legacy_hit = find(arrayfun(@(r) r.mode == "legacyDG" && r.sensor_group == sensor_group, run_outputs), 1);
    closed_hit = find(arrayfun(@(r) r.mode == "closedD" && r.sensor_group == sensor_group, run_outputs), 1);
    if isempty(legacy_hit) || isempty(closed_hit)
        continue;
    end
    group_artifacts = export_mb_semantic_gap_outputs(run_outputs(legacy_hit).run_output, run_outputs(closed_hit).run_output, paths, plot_options);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('comparison_%s', sensor_group))) = group_artifacts.tables;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('comparison_%s', sensor_group))) = group_artifacts.figures;
    group_field = matlab.lang.makeValidName(sprintf('comparison_%s', sensor_group));
    artifacts.summary.(group_field) = group_artifacts.summary;
    if ~isempty(group_artifacts.summary)
        summary_cursor = summary_cursor + 1;
        summary_rows{summary_cursor} = local_tag_comparison_summary(group_artifacts.summary, run_outputs(legacy_hit).run_output.sensor_group);
    end
end
if summary_cursor > 0
    artifacts.summary_table = vertcat(summary_rows{1:summary_cursor});
end
end

function artifacts = local_export_control_outputs(cfg, meta, run_outputs)
artifacts = struct('tables', struct(), 'figures', struct());
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
plot_options = local_semantic_plot_options(meta);
for idx = 1:numel(run_outputs)
    if run_outputs(idx).mode ~= "legacyDG"
        continue;
    end
    group_artifacts = export_mb_stage05_control_outputs(run_outputs(idx).run_output, paths, plot_options);
    sensor_group = string(run_outputs(idx).sensor_group);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('control_%s', sensor_group))) = group_artifacts.tables;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('control_%s', sensor_group))) = group_artifacts.figures;
end
end

function artifacts = local_export_cross_profile_outputs(cfg, meta, run_outputs)
artifacts = struct('tables', struct(), 'figures', struct(), 'summary', struct(), 'summary_table', table());
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
artifacts = export_mb_cross_profile_outputs(run_outputs, paths);
end

function artifacts = local_export_reliability_reports(paths, run_outputs, comparison_artifacts)
artifacts = struct();

frontier_report = build_mb_frontier_coverage_report(run_outputs);
if ~isempty(frontier_report)
    frontier_csv = fullfile(paths.tables, 'MB_frontier_coverage_report.csv');
    milestone_common_save_table(frontier_report, frontier_csv);
    artifacts.frontier_coverage_report = string(frontier_csv);
end

comparison_summary = local_getfield_or(comparison_artifacts, 'summary_table', table());
comparison_grade = table();
if isfield(comparison_artifacts, 'tables') && isstruct(comparison_artifacts.tables)
    values = struct2cell(comparison_artifacts.tables);
    for idx = 1:numel(values)
        if ~(ischar(values{idx}) || isstring(values{idx}))
            continue;
        end
        candidate = string(values{idx});
        if numel(candidate) ~= 1 || strlength(candidate) == 0 || ~contains(lower(candidate), "export_grade") || ~isfile(candidate)
            continue;
        end
        Ti = readtable(candidate, 'TextType', 'string');
        if isempty(comparison_grade)
            comparison_grade = Ti;
        else
            comparison_grade = vertcat(comparison_grade, Ti);
        end
    end
end

gap_report = build_mb_gap_reliability_report(comparison_summary, comparison_grade);
if ~isempty(gap_report)
    gap_csv = fullfile(paths.tables, 'MB_gap_reliability_report.csv');
    milestone_common_save_table(gap_report, gap_csv);
    artifacts.gap_reliability_report = string(gap_csv);
end
end

function artifacts = local_export_dense_local_outputs(cfg, meta, sensor_groups, family_set)
artifacts = struct('tables', struct(), 'figures', struct(), 'summary', struct());
if ~logical(local_getfield_or(meta, 'run_dense_local', false))
    return;
end

    paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
dense_local_sensor_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'dense_local_sensor_groups', {'baseline'}));
for idx_group = 1:numel(sensor_groups)
    sensor_group = sensor_groups{idx_group};
    if ~ismember(sensor_group, dense_local_sensor_groups)
        continue;
    end
    dense_out = run_mb_semantic_dense_local(cfg, struct( ...
        'sensor_group', sensor_group, ...
        'family_set', {family_set}, ...
        'dense_local_heights', local_getfield_or(meta, 'dense_local_heights', 1000), ...
        'anchor_h_km', local_getfield_or(meta, 'dense_local_anchor_h_km', 1000), ...
        'dense_local_i_deg', local_getfield_or(meta, 'dense_local_i_deg', 50:5:70), ...
        'dense_local_P', local_getfield_or(meta, 'dense_local_P', 6:10), ...
        'dense_local_T', local_getfield_or(meta, 'dense_local_T', [6, 8, 10, 12]), ...
        'F_fixed', local_getfield_or(meta, 'F_fixed', 1), ...
        'use_parallel', logical(local_getfield_or(meta, 'use_parallel', true))));
    group_artifacts = export_mb_semantic_dense_local_outputs(dense_out, paths);
    group_field = matlab.lang.makeValidName(sprintf('denseLocal_%s', string(sensor_group)));
    artifacts.tables.(group_field) = group_artifacts.tables;
    artifacts.figures.(group_field) = group_artifacts.figures;
    artifacts.summary.(group_field) = dense_out.summary;
end
end

function artifacts = local_export_strict_replica_validation_outputs(cfg, meta, run_outputs)
artifacts = struct('tables', struct());
stage05_replica_cfg = local_getfield_or(meta, 'stage05_replica', struct());
if ~logical(local_getfield_or(stage05_replica_cfg, 'strict', false))
    return;
end

paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
for idx = 1:numel(run_outputs)
    if run_outputs(idx).mode ~= "legacyDG"
        continue;
    end
    if string(run_outputs(idx).sensor_group) ~= "stage05_strict_reference"
        continue;
    end
    run_out = run_outputs(idx).run_output;
    if isfield(run_out, 'validation_summary') && ~isempty(run_out.validation_summary)
        validation_table = run_out.validation_summary;
    else
        [validation_table, validation_meta] = build_stage05_strict_replica_validation_summary(run_out, cfg, struct());
        [manifest_struct, manifest_table] = build_stage05_strict_replica_manifest(run_out, validation_meta);
        run_out.validation_meta = validation_meta;
        run_out.validation_manifest_struct = manifest_struct;
        run_out.validation_manifest_table = manifest_table;
    end
    validation_csv = fullfile(paths.tables, 'MB_stage05_strictReplica_validation_summary.csv');
    milestone_common_save_table(validation_table, validation_csv);
    artifacts.tables.validation_summary = string(validation_csv);
    manifest_table = local_getfield_or(run_out, 'validation_manifest_table', table());
    manifest_struct = local_getfield_or(run_out, 'validation_manifest_struct', struct());
    if ~isempty(manifest_table)
        manifest_csv = fullfile(paths.tables, 'MB_stage05_strict_replica_manifest.csv');
        milestone_common_save_table(manifest_table, manifest_csv);
        manifest_mat = fullfile(paths.tables, 'MB_stage05_strict_replica_manifest.mat');
        save(manifest_mat, 'manifest_struct');
        artifacts.tables.validation_manifest_csv = string(manifest_csv);
        artifacts.tables.validation_manifest_mat = string(manifest_mat);
    end
    return;
end
end

function summary_table = local_build_sensor_group_batch_summary(run_outputs)
row_count = 0;
for idx = 1:numel(run_outputs)
    row_count = row_count + numel(run_outputs(idx).run_output.runs);
end
summary_table = table('Size', [row_count, 10], ...
    'VariableTypes', {'string', 'string', 'string', 'double', 'double', 'double', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'sensor_label', 'max_off_boresight_deg', 'angle_resolution_arcsec', 'h_km', 'family_name', 'design_count', 'feasible_count', 'minimum_feasible_Ns'});
cursor = 0;
for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    sensor_group = run_output.sensor_group;
    for idx_run = 1:numel(run_output.runs)
        run = run_output.runs(idx_run);
        cursor = cursor + 1;
        summary_table(cursor, :) = { ...
            string(run_outputs(idx).mode), ...
            string(sensor_group.name), ...
            string(sensor_group.sensor_label), ...
            sensor_group.max_off_boresight_deg, ...
            sensor_group.angle_resolution_arcsec, ...
            run.h_km, ...
            string(run.family_name), ...
            height(run.design_table), ...
            height(run.feasible_table), ...
            local_getfield_or(run.summary, 'minimum_feasible_Ns', missing)};
    end
end
end

function tagged_summary = local_tag_comparison_summary(summary_table, sensor_group)
tagged_summary = summary_table;
row_count = height(tagged_summary);
tagged_summary = addvars(tagged_summary, ...
    repmat(string(sensor_group.name), row_count, 1), ...
    repmat(string(sensor_group.sensor_label), row_count, 1), ...
    repmat(sensor_group.max_off_boresight_deg, row_count, 1), ...
    repmat(sensor_group.angle_resolution_arcsec, row_count, 1), ...
    'Before', 1, ...
    'NewVariableNames', {'sensor_group', 'sensor_label', 'max_off_boresight_deg', 'angle_resolution_arcsec'});
end

function artifacts = local_export_sensor_group_sensitivity(cfg, meta, run_outputs)
artifacts = struct('csv', "", 'summary', struct());
profile_name = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default')));
[summary_table, sensitivity_meta] = build_mb_sensor_group_sensitivity_check(run_outputs, profile_name);
if isempty(summary_table)
    return;
end

paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
summary_csv = fullfile(paths.tables, 'MB_sensor_group_sensitivity_check.csv');
milestone_common_save_table(summary_table, summary_csv);
artifacts.csv = string(summary_csv);
artifacts.summary = sensitivity_meta;
end
