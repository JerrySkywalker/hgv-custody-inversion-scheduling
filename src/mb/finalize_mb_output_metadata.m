function artifacts = finalize_mb_output_metadata(paths, meta)
%FINALIZE_MB_OUTPUT_METADATA Append metadata columns to MB tables and write an output manifest.

artifacts = struct('manifest_csv', "", 'autotune_csv', "", 'manifest_row_count', 0);

if isfield(meta, 'auto_tune_result') && isstruct(meta.auto_tune_result) && ~isempty(fieldnames(meta.auto_tune_result))
    autotune_csv = fullfile(paths.tables, 'MB_autotune_summary.csv');
    if isfield(meta.auto_tune_result, 'summary_row') && istable(meta.auto_tune_result.summary_row) && ~isempty(meta.auto_tune_result.summary_row)
        T_auto = meta.auto_tune_result.summary_row;
    else
        T_auto = local_struct_to_kv_table(meta.auto_tune_result);
    end
    T_auto = local_append_metadata_columns(T_auto, local_infer_output_metadata('MB_autotune_summary.csv', meta));
    milestone_common_save_table(T_auto, autotune_csv);
    artifacts.autotune_csv = string(autotune_csv);
end

table_rows = local_update_output_tables_with_metadata(paths.tables, meta);
figure_rows = local_build_output_manifest_rows(paths.figures, 'figure', meta);
report_rows = local_build_output_manifest_rows(paths.tables, 'report', meta, {'*.md', '*.txt'});
manifest_rows = [table_rows; figure_rows; report_rows];
if ~isempty(manifest_rows)
    manifest_table = struct2table(manifest_rows);
    manifest_csv = fullfile(paths.tables, 'MB_output_metadata_manifest.csv');
    milestone_common_save_table(manifest_table, manifest_csv);
    artifacts.manifest_csv = string(manifest_csv);
    artifacts.manifest_row_count = height(manifest_table);
end
end

function rows = local_update_output_tables_with_metadata(tables_dir, meta)
listing = dir(fullfile(tables_dir, 'MB_*.csv'));
rows = repmat(local_empty_manifest_row(), 0, 1);
cursor = 0;
for idx = 1:numel(listing)
    file_name = listing(idx).name;
    if strcmpi(file_name, 'MB_output_metadata_manifest.csv')
        continue;
    end
    file_path = fullfile(listing(idx).folder, file_name);
    T = readtable(file_path, 'TextType', 'string');
    metadata = local_infer_output_metadata(file_name, meta);
    T = local_append_metadata_columns(T, metadata);
    milestone_common_save_table(T, file_path);

    cursor = cursor + 1;
    rows(cursor, 1) = local_manifest_row(file_path, file_name, "table", metadata);
end
rows = rows(1:cursor, 1);
end

function rows = local_build_output_manifest_rows(base_dir, artifact_kind, meta, patterns)
if nargin < 4 || isempty(patterns)
    patterns = {'*.png'};
end
rows = repmat(local_empty_manifest_row(), 0, 1);
cursor = 0;
for idx_pattern = 1:numel(patterns)
    listing = dir(fullfile(base_dir, patterns{idx_pattern}));
    for idx = 1:numel(listing)
        file_name = listing(idx).name;
        metadata = local_infer_output_metadata(file_name, meta);
        cursor = cursor + 1;
        rows(cursor, 1) = local_manifest_row(fullfile(listing(idx).folder, file_name), file_name, string(artifact_kind), metadata);
    end
end
rows = rows(1:cursor, 1);
end

function metadata = local_infer_output_metadata(file_name, meta)
lower_name = lower(char(string(file_name)));
metadata = struct();
metadata.semantic_mode = string(local_getfield_or(meta, 'mode', 'comparison'));
metadata.sensor_group = string(strjoin(resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'})), ','));
metadata.search_profile = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default')));
metadata.search_profile_mode = string(local_getfield_or(meta, 'search_profile_mode', 'debug'));
metadata.stage05_replica_flag = logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false));
metadata.auto_tuned_flag = logical(local_getfield_or(meta, 'auto_tuned_flag', false));

if contains(lower_name, 'mb_legacydg_')
    metadata.semantic_mode = "legacyDG";
elseif contains(lower_name, 'mb_closedd_')
    metadata.semantic_mode = "closedD";
elseif contains(lower_name, 'mb_comparison_')
    metadata.semantic_mode = "comparison";
elseif contains(lower_name, 'mb_control_stage05_')
    metadata.semantic_mode = "legacyDG";
elseif contains(lower_name, 'mb_stage05_strictreplica')
    metadata.semantic_mode = "legacyDG";
    metadata.stage05_replica_flag = true;
elseif contains(lower_name, 'mb_denselocal_')
    metadata.semantic_mode = "comparison";
elseif contains(lower_name, 'mb_run_manifest') || contains(lower_name, 'mb_sensor_group_manifest')
    metadata.semantic_mode = "manifest";
end

group_hits = {'baseline', 'optimistic', 'robust', 'stage05_strict_reference'};
for idx = 1:numel(group_hits)
    if contains(lower_name, lower(group_hits{idx}))
        metadata.sensor_group = string(group_hits{idx});
        return;
    end
end
if contains(lower_name, 'strictreplica')
    metadata.sensor_group = "stage05_strict_reference";
elseif contains(lower_name, 'batch')
    metadata.sensor_group = "batch";
end
end

function T = local_append_metadata_columns(T, metadata)
meta_table = table( ...
    repmat(string(metadata.semantic_mode), height(T), 1), ...
    repmat(string(metadata.sensor_group), height(T), 1), ...
    repmat(string(metadata.search_profile), height(T), 1), ...
    repmat(string(metadata.search_profile_mode), height(T), 1), ...
    repmat(logical(metadata.stage05_replica_flag), height(T), 1), ...
    repmat(logical(metadata.auto_tuned_flag), height(T), 1), ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'search_profile', 'search_profile_mode', 'stage05_replica_flag', 'auto_tuned_flag'});

meta_names = meta_table.Properties.VariableNames;
for idx = 1:numel(meta_names)
    var_name = meta_names{idx};
    if ismember(var_name, T.Properties.VariableNames)
        T.(var_name) = meta_table.(var_name);
    else
        T = addvars(T, meta_table.(var_name), 'Before', 1, 'NewVariableNames', var_name);
    end
end
T = movevars(T, meta_names, 'Before', 1);
end

function row = local_manifest_row(file_path, file_name, artifact_kind, metadata)
row = local_empty_manifest_row();
row.file_path = string(file_path);
row.file_name = string(file_name);
row.artifact_kind = string(artifact_kind);
row.semantic_mode = string(metadata.semantic_mode);
row.sensor_group = string(metadata.sensor_group);
row.search_profile = string(metadata.search_profile);
row.search_profile_mode = string(metadata.search_profile_mode);
row.stage05_replica_flag = logical(metadata.stage05_replica_flag);
row.auto_tuned_flag = logical(metadata.auto_tuned_flag);
end

function row = local_empty_manifest_row()
row = struct( ...
    'file_path', "", ...
    'file_name', "", ...
    'artifact_kind', "", ...
    'semantic_mode', "", ...
    'sensor_group', "", ...
    'search_profile', "", ...
    'search_profile_mode', "", ...
    'stage05_replica_flag', false, ...
    'auto_tuned_flag', false);
end

function T = local_struct_to_kv_table(S)
names = fieldnames(S);
values = strings(numel(names), 1);
for idx = 1:numel(names)
    values(idx) = string(local_stringify(S.(names{idx})));
end
T = table(string(names), values, 'VariableNames', {'field', 'value'});
end

function txt = local_stringify(value)
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

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
