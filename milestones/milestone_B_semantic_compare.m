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
result.summary.execution_status = "executed";
result.summary.run_count = numel(run_outputs);

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function outputs = local_execute_semantic_runs(cfg, meta, resolved_modes, sensor_groups, family_set, heights_to_run)
outputs = repmat(struct( ...
    'mode', "", ...
    'sensor_group', "", ...
    'run_output', struct()), local_count_wrapped_runs(resolved_modes, numel(sensor_groups)), 1);
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

    for idx_mode = 1:numel(resolved_modes)
        mode_entry = resolved_modes(idx_mode);
        if mode_entry.uses_legacydg
            cursor = cursor + 1;
            outputs(cursor, 1) = struct( ...
                'mode', "legacyDG", ...
                'sensor_group', string(sensor_group), ...
                'run_output', run_mb_legacydg_semantics(cfg, common_options));
        end
        if mode_entry.uses_closedd
            cursor = cursor + 1;
            outputs(cursor, 1) = struct( ...
                'mode', "closedD", ...
                'sensor_group', string(sensor_group), ...
                'run_output', run_mb_closedd_semantics(cfg, common_options));
        end
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

function count = local_count_wrapped_runs(resolved_modes, sensor_group_count)
count_per_group = 0;
for idx = 1:numel(resolved_modes)
    mode_entry = resolved_modes(idx);
    count_per_group = count_per_group + double(mode_entry.uses_legacydg) + double(mode_entry.uses_closedd);
end
count = sensor_group_count * count_per_group;
end
