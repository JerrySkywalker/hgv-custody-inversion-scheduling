function result = milestone_B_semantic_compare(cfg)
%MILESTONE_B_SEMANTIC_COMPARE Unified MB semantic-comparison entry point.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MB_semantic_compare;
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
paths.summary_report = fullfile(paths.tables, 'MB_run_manifest.md');
paths.summary_mat = fullfile(paths.tables, 'MB_semantic_compare_summary.mat');

resolved_modes = mb_modes(local_getfield_or(meta, 'mode', 'comparison'));
resolved_sensor_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'}));
resolved_families = local_resolve_family_set(local_getfield_or(meta, 'family_set', {'nominal'}));
resolved_heights = reshape(local_getfield_or(meta, 'heights_to_run', 1000), 1, []);

sensor_manifest = local_build_sensor_manifest(resolved_sensor_groups);
run_manifest = local_build_run_manifest(resolved_modes, resolved_sensor_groups, resolved_families, resolved_heights);
sensor_manifest_csv = fullfile(paths.tables, 'MB_sensor_group_manifest.csv');
run_manifest_csv = fullfile(paths.tables, 'MB_run_manifest.csv');
milestone_common_save_table(sensor_manifest, sensor_manifest_csv);
milestone_common_save_table(run_manifest, run_manifest_csv);
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
    'run_manifest', string(run_manifest_csv));
result.figures = struct();
result.artifacts = struct( ...
    'summary_report', string(paths.summary_report), ...
    'summary_mat', string(paths.summary_mat), ...
    'cache_dir', string(paths.cache));
result.summary = struct( ...
    'mode', string(local_getfield_or(meta, 'mode', 'comparison')), ...
    'resolved_modes', {cellstr(string({resolved_modes.name}))}, ...
    'sensor_groups', {resolved_sensor_groups}, ...
    'families', {resolved_families}, ...
    'heights_to_run', resolved_heights, ...
    'dry_run', logical(local_getfield_or(meta, 'dry_run', false)), ...
    'fast_mode', logical(local_getfield_or(meta, 'fast_mode', false)), ...
    'resume_checkpoint', logical(local_getfield_or(meta, 'resume_checkpoint', false)), ...
    'run_dense_local', logical(local_getfield_or(meta, 'run_dense_local', false)), ...
    'baseline_validation_only', isequal(resolved_sensor_groups, {'baseline'}));

if logical(local_getfield_or(meta, 'dry_run', false))
    result.summary.execution_status = "dry-run";
    files = milestone_common_export_summary(result, paths);
    result.artifacts.summary_report = files.report_md;
    result.artifacts.summary_mat = files.summary_mat;
    return;
end

run_outputs = local_execute_semantic_runs(cfg, meta, resolved_modes, resolved_sensor_groups, resolved_families, resolved_heights);
result.artifacts.run_outputs = run_outputs;
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
comparison_artifacts = local_export_comparison_outputs(cfg, resolved_modes, resolved_sensor_groups, run_outputs);
if ~isempty(fieldnames(comparison_artifacts.tables))
    result.tables.comparison = comparison_artifacts.tables;
end
if ~isempty(fieldnames(comparison_artifacts.figures))
    result.figures.comparison = comparison_artifacts.figures;
end
if isfield(comparison_artifacts, 'summary')
    result.summary.comparison = comparison_artifacts.summary;
end
control_artifacts = local_export_control_outputs(cfg, run_outputs);
if ~isempty(fieldnames(control_artifacts.tables))
    result.tables.control = control_artifacts.tables;
end
if ~isempty(fieldnames(control_artifacts.figures))
    result.figures.control = control_artifacts.figures;
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
result.summary.execution_status = "executed";
result.summary.run_count = numel(run_outputs);

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function outputs = local_execute_semantic_runs(cfg, meta, resolved_modes, sensor_groups, family_set, heights_to_run)
need_legacy = any(arrayfun(@(m) logical(m.uses_legacydg), resolved_modes));
need_closed = any(arrayfun(@(m) logical(m.uses_closedd), resolved_modes));
outputs = repmat(struct( ...
    'mode', "", ...
    'sensor_group', "", ...
    'run_output', struct(), ...
    'artifacts', struct()), local_count_wrapped_runs(need_legacy, need_closed, numel(sensor_groups)), 1);
cursor = 0;

for idx_group = 1:numel(sensor_groups)
    sensor_group = sensor_groups{idx_group};
    common_options = struct( ...
        'sensor_group', sensor_group, ...
        'heights_to_run', heights_to_run, ...
        'family_set', {family_set}, ...
        'i_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
        'P_grid', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
        'T_grid', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
        'F_fixed', local_getfield_or(meta, 'F_fixed', 1), ...
        'use_parallel', logical(local_getfield_or(meta, 'use_parallel', true)));

    if need_legacy
        cursor = cursor + 1;
        legacy_output = run_mb_legacydg_semantics(cfg, common_options);
        outputs(cursor, 1) = struct( ...
            'mode', "legacyDG", ...
            'sensor_group', string(sensor_group), ...
            'run_output', legacy_output, ...
            'artifacts', export_mb_legacydg_outputs(legacy_output, mb_output_paths(cfg, 'MB', 'semantic_compare')));
    end
    if need_closed
        cursor = cursor + 1;
        closed_output = run_mb_closedd_semantics(cfg, common_options);
        outputs(cursor, 1) = struct( ...
            'mode', "closedD", ...
            'sensor_group', string(sensor_group), ...
            'run_output', closed_output, ...
            'artifacts', export_mb_closedd_outputs(closed_output, mb_output_paths(cfg, 'MB', 'semantic_compare')));
    end
end
outputs = outputs(1:cursor, 1);
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

function manifest = local_build_run_manifest(resolved_modes, sensor_groups, family_set, heights_to_run)
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
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# MB Semantic Compare Run Manifest\n\n');
fprintf(fid, '- `mode`: %s\n', char(string(local_getfield_or(meta, 'mode', 'comparison'))));
fprintf(fid, '- `sensor_groups`: %s\n', strjoin(sensor_groups, ', '));
fprintf(fid, '- `families`: %s\n', strjoin(family_set, ', '));
fprintf(fid, '- `heights_to_run_km`: %s\n', mat2str(heights_to_run));
fprintf(fid, '- `dry_run`: %s\n', char(string(logical(local_getfield_or(meta, 'dry_run', false)))));
fprintf(fid, '- `fast_mode`: %s\n', char(string(logical(local_getfield_or(meta, 'fast_mode', false)))));
fprintf(fid, '- `run_dense_local`: %s\n\n', char(string(logical(local_getfield_or(meta, 'run_dense_local', false)))));

fprintf(fid, '## Modes\n\n');
for idx = 1:numel(resolved_modes)
    mode_entry = resolved_modes(idx);
    fprintf(fid, '- `%s`: %s\n', mode_entry.name, mode_entry.description);
end
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

function artifacts = local_export_comparison_outputs(cfg, resolved_modes, sensor_groups, run_outputs)
artifacts = struct('tables', struct(), 'figures', struct());
if ~any(arrayfun(@(m) logical(m.emits_gap_outputs), resolved_modes))
    return;
end

paths = mb_output_paths(cfg, 'MB', 'semantic_compare');
for idx_group = 1:numel(sensor_groups)
    sensor_group = string(sensor_groups{idx_group});
    legacy_hit = find(arrayfun(@(r) r.mode == "legacyDG" && r.sensor_group == sensor_group, run_outputs), 1);
    closed_hit = find(arrayfun(@(r) r.mode == "closedD" && r.sensor_group == sensor_group, run_outputs), 1);
    if isempty(legacy_hit) || isempty(closed_hit)
        continue;
    end
    group_artifacts = export_mb_semantic_gap_outputs(run_outputs(legacy_hit).run_output, run_outputs(closed_hit).run_output, paths);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('comparison_%s', sensor_group))) = group_artifacts.tables;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('comparison_%s', sensor_group))) = group_artifacts.figures;
    artifacts.summary = group_artifacts.summary;
end
end

function artifacts = local_export_control_outputs(cfg, run_outputs)
artifacts = struct('tables', struct(), 'figures', struct());
paths = mb_output_paths(cfg, 'MB', 'semantic_compare');
for idx = 1:numel(run_outputs)
    if run_outputs(idx).mode ~= "legacyDG"
        continue;
    end
    group_artifacts = export_mb_stage05_control_outputs(run_outputs(idx).run_output, paths);
    sensor_group = string(run_outputs(idx).sensor_group);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('control_%s', sensor_group))) = group_artifacts.tables;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('control_%s', sensor_group))) = group_artifacts.figures;
end
end

function artifacts = local_export_dense_local_outputs(cfg, meta, sensor_groups, family_set)
artifacts = struct('tables', struct(), 'figures', struct());
if ~logical(local_getfield_or(meta, 'run_dense_local', false))
    return;
end

paths = mb_output_paths(cfg, 'MB', 'semantic_compare');
for idx_group = 1:numel(sensor_groups)
    sensor_group = sensor_groups{idx_group};
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
    artifacts.summary = dense_out.summary;
end
end
