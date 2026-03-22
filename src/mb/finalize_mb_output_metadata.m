function artifacts = finalize_mb_output_metadata(paths, context)
%FINALIZE_MB_OUTPUT_METADATA Append metadata columns to MB tables and write an output manifest.

artifacts = struct('manifest_csv', "", 'autotune_csv', "", 'manifest_row_count', 0);
context = local_normalize_context(context);
meta = context.meta;

if isfield(meta, 'auto_tune_result') && isstruct(meta.auto_tune_result) && ~isempty(fieldnames(meta.auto_tune_result))
    autotune_csv = fullfile(paths.tables, 'MB_autotune_summary.csv');
    if isfield(meta.auto_tune_result, 'summary_row') && istable(meta.auto_tune_result.summary_row) && ~isempty(meta.auto_tune_result.summary_row)
        T_auto = meta.auto_tune_result.summary_row;
    else
        T_auto = local_struct_to_kv_table(meta.auto_tune_result);
    end
    auto_meta = local_infer_output_metadata('MB_autotune_summary.csv', autotune_csv, context);
    T_auto = local_append_metadata_columns(T_auto, auto_meta);
    milestone_common_save_table(T_auto, autotune_csv);
    local_write_metadata_sidecar(autotune_csv, auto_meta);
    artifacts.autotune_csv = string(autotune_csv);
end

table_rows = local_update_output_tables_with_metadata(paths.tables, context);
figure_rows = local_build_output_manifest_rows(paths.figures, 'figure', context);
report_rows = local_build_output_manifest_rows(paths.tables, 'report', context, {'*.md', '*.txt'});
manifest_rows = [table_rows; figure_rows; report_rows];
if ~isempty(manifest_rows)
    manifest_table = struct2table(manifest_rows);
    manifest_csv = fullfile(paths.tables, 'MB_output_metadata_manifest.csv');
    milestone_common_save_table(manifest_table, manifest_csv);
    artifacts.manifest_csv = string(manifest_csv);
    artifacts.manifest_row_count = height(manifest_table);
end
end

function rows = local_update_output_tables_with_metadata(tables_dir, context)
listing = local_resolve_artifact_listing(tables_dir, context, "table");
rows = repmat(local_empty_manifest_row(), 0, 1);
cursor = 0;
for idx = 1:numel(listing)
    file_name = listing(idx).name;
    if strcmpi(file_name, 'MB_output_metadata_manifest.csv')
        continue;
    end
    file_path = fullfile(listing(idx).folder, file_name);
    T = readtable(file_path, 'TextType', 'string');
    metadata = local_infer_output_metadata(file_name, file_path, context);
    T = local_append_metadata_columns(T, metadata);
    milestone_common_save_table(T, file_path);
    local_write_metadata_sidecar(file_path, metadata);

    cursor = cursor + 1;
    rows(cursor, 1) = local_manifest_row(file_path, file_name, "table", metadata);
end
rows = rows(1:cursor, 1);
end

function rows = local_build_output_manifest_rows(base_dir, artifact_kind, context, patterns)
if nargin < 4 || isempty(patterns)
    patterns = {'*.png'};
end
listing = local_resolve_artifact_listing(base_dir, context, artifact_kind, patterns);
rows = repmat(local_empty_manifest_row(), 0, 1);
cursor = 0;
for idx = 1:numel(listing)
    file_name = listing(idx).name;
    file_path = fullfile(listing(idx).folder, file_name);
    metadata = local_infer_output_metadata(file_name, file_path, context);
    local_write_metadata_sidecar(file_path, metadata);
    cursor = cursor + 1;
    rows(cursor, 1) = local_manifest_row(file_path, file_name, string(artifact_kind), metadata);
end
rows = rows(1:cursor, 1);
end

function metadata = local_infer_output_metadata(file_name, file_path, context)
lower_name = lower(char(string(file_name)));
meta = context.meta;
metadata = local_default_metadata(meta);
[metadata, had_sidecar] = local_merge_existing_sidecar(file_path, metadata);
is_current_artifact = local_is_current_artifact(file_path, context);
if is_current_artifact
    metadata.semantic_mode = string(local_getfield_or(meta, 'mode', 'comparison'));
    metadata.sensor_group = string(strjoin(resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'})), ','));
    metadata.search_profile = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default')));
    metadata.search_profile_mode = string(local_getfield_or(meta, 'search_profile_mode', 'debug'));
    metadata.figure_style_mode = string(local_getfield_or(meta, 'figure_style_mode', 'diagnostic'));
    metadata.snapshot_stage = "expanded_final";
    metadata.plot_domain_mode = string(local_getfield_or(meta, 'plot_domain_policy', local_getfield_or(meta, 'plot_xlim_mode', "data_range")));
    metadata.search_domain_ns = local_stringify(local_getfield_or(meta, 'Ns_initial_range', []));
    metadata.search_domain_p = local_stringify(local_getfield_or(meta, 'P_grid', []));
    metadata.search_domain_t = local_stringify(local_getfield_or(meta, 'T_grid', []));
    metadata.expand_blocks = local_expand_blocks_text(local_getfield_or(meta, 'Ns_expand_blocks', []));
else
    metadata.semantic_mode = local_fill_missing_string(metadata.semantic_mode, local_getfield_or(meta, 'mode', 'comparison'));
    metadata.sensor_group = local_fill_missing_string(metadata.sensor_group, strjoin(resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'})), ','));
    metadata.search_profile = local_fill_missing_string(metadata.search_profile, local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default')));
    metadata.search_profile_mode = local_fill_missing_string(metadata.search_profile_mode, local_getfield_or(meta, 'search_profile_mode', 'debug'));
    metadata.figure_style_mode = local_fill_missing_string(metadata.figure_style_mode, local_getfield_or(meta, 'figure_style_mode', 'diagnostic'));
    metadata.snapshot_stage = local_fill_missing_string(metadata.snapshot_stage, "expanded_final");
    metadata.plot_domain_mode = local_fill_missing_string(metadata.plot_domain_mode, local_getfield_or(meta, 'plot_domain_policy', local_getfield_or(meta, 'plot_xlim_mode', "data_range")));
    metadata.search_domain_ns = local_fill_missing_string(metadata.search_domain_ns, local_stringify(local_getfield_or(meta, 'Ns_initial_range', [])));
    metadata.search_domain_p = local_fill_missing_string(metadata.search_domain_p, local_stringify(local_getfield_or(meta, 'P_grid', [])));
    metadata.search_domain_t = local_fill_missing_string(metadata.search_domain_t, local_stringify(local_getfield_or(meta, 'T_grid', [])));
    metadata.expand_blocks = local_fill_missing_string(metadata.expand_blocks, local_expand_blocks_text(local_getfield_or(meta, 'Ns_expand_blocks', [])));
end
metadata.height_km = local_fill_missing_numeric(metadata.height_km, NaN);
if is_current_artifact
    metadata.stage05_replica_flag = logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false));
    metadata.auto_tuned_flag = logical(local_getfield_or(meta, 'auto_tuned_flag', false));
    metadata.expand_enabled = logical(local_getfield_or(meta, 'Ns_allow_expand', false));
    metadata.ns_hard_max = local_getfield_or(meta, 'Ns_hard_max', NaN);
else
    if ~logical(local_getfield_or(metadata, 'stage05_replica_flag', false))
        metadata.stage05_replica_flag = logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false));
    end
    if ~logical(local_getfield_or(metadata, 'auto_tuned_flag', false))
        metadata.auto_tuned_flag = logical(local_getfield_or(meta, 'auto_tuned_flag', false));
    end
    if ~logical(local_getfield_or(metadata, 'expand_enabled', false))
        metadata.expand_enabled = logical(local_getfield_or(meta, 'Ns_allow_expand', false));
    end
    if ~isfinite(local_getfield_or(metadata, 'ns_hard_max', NaN))
        metadata.ns_hard_max = local_getfield_or(meta, 'Ns_hard_max', NaN);
    end
end

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

if contains(lower_name, 'paperready')
    metadata.figure_style_mode = "paper_ready";
end
if contains(lower_name, 'historyfull')
    metadata.plot_domain_mode = "history_full";
    metadata.x_domain_origin = "initial_search_domain_lower_bound";
elseif contains(lower_name, 'effectivefullrange') || contains(lower_name, 'fullrange') || contains(lower_name, 'globaltrend')
    metadata.plot_domain_mode = "effective_full_range";
    metadata.x_domain_origin = "effective_search_domain";
elseif contains(lower_name, 'frontierzoom')
    metadata.plot_domain_mode = "frontier_zoom";
    metadata.x_domain_origin = "frontier_zoom_window";
elseif contains(lower_name, 'globalskeleton')
    metadata.plot_domain_mode = "global_skeleton_surface";
elseif contains(lower_name, 'local')
    metadata.plot_domain_mode = "local_defined_surface";
end
if contains(lower_name, 'minimumns_heatmap')
    metadata.heatmap_value_semantics = "minimum_feasible_ns";
elseif contains(lower_name, 'statemap')
    metadata.heatmap_value_semantics = "state_map_discrete";
elseif contains(lower_name, 'gap_heatmap')
    metadata.heatmap_value_semantics = "semantic_gap";
end
if contains(lower_name, 'globalskeleton')
    metadata.heatmap_surface_mode = "global_skeleton";
elseif contains(lower_name, 'local')
    metadata.heatmap_surface_mode = "local";
end
if contains(lower_name, 'strictreplica') || contains(lower_name, 'strict_replica')
    metadata.snapshot_stage = "strict_replica";
end
if contains(lower_name, 'initial')
    metadata.snapshot_stage = "initial";
elseif contains(lower_name, 'preferred')
    metadata.snapshot_stage = "preferred_xlim";
elseif contains(lower_name, 'expanded')
    metadata.snapshot_stage = "expanded";
end

group_hits = {'baseline', 'optimistic', 'robust', 'stage05_strict_reference'};
for idx = 1:numel(group_hits)
    if contains(lower_name, lower(group_hits{idx}))
        metadata.sensor_group = string(group_hits{idx});
        break;
    end
end
if contains(lower_name, 'strictreplica')
    metadata.sensor_group = "stage05_strict_reference";
elseif contains(lower_name, 'batch')
    metadata.sensor_group = "batch";
end

height_tokens = regexp(lower_name, 'h(\d+)', 'tokens', 'once');
if ~isempty(height_tokens)
    metadata.height_km = str2double(height_tokens{1});
end

run_meta = local_lookup_run_metadata(context, metadata.semantic_mode, metadata.sensor_group, metadata.height_km);
metadata = local_merge_run_metadata(metadata, run_meta);
metadata = local_clear_unmatched_runtime_defaults(metadata, run_meta, had_sidecar);
end

function tf = local_is_current_artifact(file_path, context)
artifact_files = string(local_getfield_or(context, 'artifact_files', strings(0, 1)));
if isempty(artifact_files)
    tf = false;
    return;
end
tf = any(strcmpi(artifact_files, string(file_path)));
end

function T = local_append_metadata_columns(T, metadata)
meta_table = table( ...
    repmat(string(metadata.semantic_mode), height(T), 1), ...
    repmat(string(metadata.sensor_group), height(T), 1), ...
    repmat(string(metadata.search_profile), height(T), 1), ...
    repmat(string(metadata.search_profile_mode), height(T), 1), ...
    repmat(string(metadata.snapshot_stage), height(T), 1), ...
    repmat(string(metadata.plot_domain_mode), height(T), 1), ...
    repmat(string(local_getfield_or(metadata, 'x_domain_origin', "")), height(T), 1), ...
    repmat(double(local_getfield_or(metadata, 'x_min_rendered', NaN)), height(T), 1), ...
    repmat(double(local_getfield_or(metadata, 'x_max_rendered', NaN)), height(T), 1), ...
    repmat(string(local_getfield_or(metadata, 'heatmap_surface_mode', "")), height(T), 1), ...
    repmat(string(local_getfield_or(metadata, 'heatmap_value_semantics', "")), height(T), 1), ...
    repmat(string(metadata.figure_style_mode), height(T), 1), ...
    repmat(logical(metadata.stage05_replica_flag), height(T), 1), ...
    repmat(logical(metadata.auto_tuned_flag), height(T), 1), ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'search_profile', 'search_profile_mode', 'snapshot_stage', 'plot_domain_mode', 'x_domain_origin', 'x_min_rendered', 'x_max_rendered', 'heatmap_surface_mode', 'heatmap_value_semantics', 'figure_style_mode', 'stage05_replica_flag', 'auto_tuned_flag'});

meta_names = meta_table.Properties.VariableNames;
added_names = strings(0, 1);
for idx = 1:numel(meta_names)
    var_name = meta_names{idx};
    if ismember(var_name, T.Properties.VariableNames)
        if local_preserve_existing_column(T.(var_name), meta_table.(var_name))
            artifact_name = matlab.lang.makeUniqueStrings("artifact_" + string(var_name), string(T.Properties.VariableNames));
            T.(char(artifact_name)) = meta_table.(var_name);
            added_names(end + 1, 1) = artifact_name; %#ok<AGROW>
        else
            T.(var_name) = meta_table.(var_name);
        end
    else
        T = addvars(T, meta_table.(var_name), 'Before', 1, 'NewVariableNames', var_name);
        added_names(end + 1, 1) = string(var_name); %#ok<AGROW>
    end
end
move_names = meta_names(ismember(meta_names, T.Properties.VariableNames));
if ~isempty(move_names)
    T = movevars(T, move_names, 'Before', 1);
end
artifact_names = cellstr(added_names(strlength(added_names) > 0));
artifact_names = artifact_names(ismember(artifact_names, T.Properties.VariableNames));
if ~isempty(artifact_names)
    T = movevars(T, artifact_names, 'Before', 1);
end
end

function tf = local_preserve_existing_column(existing_values, new_values)
tf = false;
if isempty(existing_values)
    return;
end

existing_clean = local_unique_nonmissing(existing_values);
new_clean = local_unique_nonmissing(new_values);

if numel(existing_clean) > 1
    tf = true;
    return;
end
if isempty(existing_clean)
    tf = false;
    return;
end
if isempty(new_clean)
    tf = true;
    return;
end

tf = ~isequal(existing_clean, new_clean);
end

function values = local_unique_nonmissing(data)
if isstring(data) || ischar(data)
    values = unique(string(data(:)));
    values = values(strlength(values) > 0 & ~ismissing(values));
elseif iscellstr(data) || iscell(data)
    values = unique(string(data(:)));
    values = values(strlength(values) > 0 & ~ismissing(values));
elseif isnumeric(data) || islogical(data)
    values = unique(data(:));
    values = values(~isnan(values));
else
    values = unique(string(data(:)));
    values = values(strlength(values) > 0 & ~ismissing(values));
end
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
row.snapshot_stage = string(metadata.snapshot_stage);
row.plot_domain_mode = string(metadata.plot_domain_mode);
row.x_domain_origin = string(local_getfield_or(metadata, 'x_domain_origin', ""));
row.x_min_rendered = local_getfield_or(metadata, 'x_min_rendered', NaN);
row.x_max_rendered = local_getfield_or(metadata, 'x_max_rendered', NaN);
row.heatmap_surface_mode = string(local_getfield_or(metadata, 'heatmap_surface_mode', ""));
row.heatmap_value_semantics = string(local_getfield_or(metadata, 'heatmap_value_semantics', ""));
row.figure_style_mode = string(metadata.figure_style_mode);
row.stage05_replica_flag = logical(metadata.stage05_replica_flag);
row.auto_tuned_flag = logical(metadata.auto_tuned_flag);
row.height_km = local_getfield_or(metadata, 'height_km', NaN);
row.search_domain_ns = string(local_getfield_or(metadata, 'search_domain_ns', ""));
row.search_domain_p = string(local_getfield_or(metadata, 'search_domain_p', ""));
row.search_domain_t = string(local_getfield_or(metadata, 'search_domain_t', ""));
row.expand_enabled = logical(local_getfield_or(metadata, 'expand_enabled', false));
row.expand_blocks = string(local_getfield_or(metadata, 'expand_blocks', ""));
row.ns_hard_max = local_getfield_or(metadata, 'ns_hard_max', NaN);
row.expansion_stop_reason = string(local_getfield_or(metadata, 'expansion_stop_reason', ""));
row.boundary_hit_detected = logical(local_getfield_or(metadata, 'boundary_hit_detected', false));
row.frontier_defined_ratio = local_getfield_or(metadata, 'frontier_defined_ratio', NaN);
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
    'snapshot_stage', "", ...
    'plot_domain_mode', "", ...
    'x_domain_origin', "", ...
    'x_min_rendered', NaN, ...
    'x_max_rendered', NaN, ...
    'heatmap_surface_mode', "", ...
    'heatmap_value_semantics', "", ...
    'figure_style_mode', "", ...
    'stage05_replica_flag', false, ...
    'auto_tuned_flag', false, ...
    'height_km', NaN, ...
    'search_domain_ns', "", ...
    'search_domain_p', "", ...
    'search_domain_t', "", ...
    'expand_enabled', false, ...
    'expand_blocks', "", ...
    'ns_hard_max', NaN, ...
    'expansion_stop_reason', "", ...
    'boundary_hit_detected', false, ...
    'frontier_defined_ratio', NaN);
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

function metadata = local_default_metadata(meta)
metadata = struct();
metadata.semantic_mode = string(local_getfield_or(meta, 'mode', 'comparison'));
metadata.sensor_group = string(strjoin(resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'})), ','));
metadata.search_profile = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', 'mb_default')));
metadata.search_profile_mode = string(local_getfield_or(meta, 'search_profile_mode', 'debug'));
metadata.figure_style_mode = string(local_getfield_or(meta, 'figure_style_mode', 'diagnostic'));
metadata.stage05_replica_flag = logical(local_getfield_or(local_getfield_or(meta, 'stage05_replica', struct()), 'strict', false));
metadata.auto_tuned_flag = logical(local_getfield_or(meta, 'auto_tuned_flag', false));
metadata.snapshot_stage = "expanded_final";
metadata.plot_domain_mode = string(local_getfield_or(meta, 'plot_domain_policy', local_getfield_or(meta, 'plot_xlim_mode', "data_range")));
metadata.x_domain_origin = "";
metadata.x_min_rendered = NaN;
metadata.x_max_rendered = NaN;
metadata.heatmap_surface_mode = "";
metadata.heatmap_value_semantics = "";
metadata.search_domain_ns = local_stringify(local_getfield_or(meta, 'Ns_initial_range', []));
metadata.search_domain_p = local_stringify(local_getfield_or(meta, 'P_grid', []));
metadata.search_domain_t = local_stringify(local_getfield_or(meta, 'T_grid', []));
metadata.expand_enabled = logical(local_getfield_or(meta, 'Ns_allow_expand', false));
metadata.expand_blocks = local_expand_blocks_text(local_getfield_or(meta, 'Ns_expand_blocks', []));
metadata.ns_hard_max = local_getfield_or(meta, 'Ns_hard_max', NaN);
metadata.expansion_stop_reason = "";
metadata.boundary_hit_detected = false;
metadata.frontier_defined_ratio = NaN;
metadata.height_km = NaN;
end

function value = local_fill_missing_string(existing_value, fallback)
value = string(existing_value);
if strlength(value) == 0 || ismissing(value)
    value = string(fallback);
end
end

function value = local_fill_missing_numeric(existing_value, fallback)
value = existing_value;
if isempty(value)
    value = fallback;
elseif isnumeric(value) && isscalar(value) && isnan(value) && isfinite(fallback)
    value = fallback;
end
end

function [metadata, had_sidecar] = local_merge_existing_sidecar(file_path, metadata)
sidecar_path = local_sidecar_path(file_path);
if exist(sidecar_path, 'file') ~= 2
    had_sidecar = false;
    return;
end
had_sidecar = true;
try
    raw = fileread(sidecar_path);
    loaded = jsondecode(raw);
    names = fieldnames(loaded);
    for idx = 1:numel(names)
        metadata.(names{idx}) = loaded.(names{idx});
    end
catch
    warning('MB:MetadataSidecar', 'Failed to read existing metadata sidecar: %s', sidecar_path);
    had_sidecar = false;
end
end

function metadata = local_clear_unmatched_runtime_defaults(metadata, run_meta, had_sidecar)
if ~isempty(fieldnames(run_meta))
    return;
end
if had_sidecar
    return;
end
if ~isfinite(local_getfield_or(metadata, 'height_km', NaN))
    return;
end
metadata.search_profile = "unresolved_from_current_context";
metadata.search_profile_mode = "";
metadata.search_domain_ns = "";
metadata.search_domain_p = "";
metadata.search_domain_t = "";
metadata.expand_enabled = false;
metadata.expand_blocks = "";
metadata.ns_hard_max = NaN;
metadata.expansion_stop_reason = "";
metadata.boundary_hit_detected = false;
metadata.frontier_defined_ratio = NaN;
end

function context = local_normalize_context(context_in)
if nargin < 1 || isempty(context_in)
    context_in = struct();
end
if isstruct(context_in) && isfield(context_in, 'meta')
    context = context_in;
else
    context = struct('meta', context_in);
end
if ~isfield(context, 'meta') || isempty(context.meta)
    context.meta = struct();
end
if ~isfield(context, 'run_outputs')
    context.run_outputs = repmat(struct(), 0, 1);
end
if ~isfield(context, 'artifact_files')
    context.artifact_files = strings(0, 1);
else
    context.artifact_files = string(context.artifact_files(:));
end
end

function listing = local_resolve_artifact_listing(base_dir, context, artifact_kind, patterns)
if nargin < 4 || isempty(patterns)
    patterns = {'*.csv'};
end
artifact_files = string(local_getfield_or(context, 'artifact_files', strings(0, 1)));
if isempty(artifact_files)
    listing = local_scan_artifact_listing(base_dir, patterns);
    return;
end

allowed_ext = local_extensions_for_artifact_kind(string(artifact_kind), patterns);
listing = repmat(struct('name', "", 'folder', "", 'date', "", 'bytes', 0, 'isdir', false, 'datenum', 0), 0, 1);
cursor = 0;
for idx = 1:numel(artifact_files)
    file_path = artifact_files(idx);
    if strlength(file_path) == 0 || exist(file_path, 'file') ~= 2
        continue;
    end
    [folder, name, ext] = fileparts(char(file_path));
    if ~strcmpi(string(folder), string(base_dir))
        continue;
    end
    if ~any(strcmpi(string(ext), allowed_ext))
        continue;
    end
    cursor = cursor + 1;
    listing(cursor, 1) = dir(char(file_path)); %#ok<AGROW>
end
listing = listing(1:cursor, 1);
end

function listing = local_scan_artifact_listing(base_dir, patterns)
listing = repmat(struct('name', "", 'folder', "", 'date', "", 'bytes', 0, 'isdir', false, 'datenum', 0), 0, 1);
cursor = 0;
for idx_pattern = 1:numel(patterns)
    found = dir(fullfile(base_dir, patterns{idx_pattern}));
    for idx = 1:numel(found)
        cursor = cursor + 1;
        listing(cursor, 1) = found(idx); %#ok<AGROW>
    end
end
listing = listing(1:cursor, 1);
end

function ext = local_extensions_for_artifact_kind(artifact_kind, patterns)
switch lower(char(artifact_kind))
    case 'table'
        ext = ".csv";
    case 'figure'
        ext = ".png";
    case 'report'
        ext = [".md"; ".txt"];
    otherwise
        ext = strings(0, 1);
        for idx = 1:numel(patterns)
            [~, ~, current_ext] = fileparts(patterns{idx});
            ext(end + 1, 1) = string(current_ext); %#ok<AGROW>
        end
end
end

function run_meta = local_lookup_run_metadata(context, semantic_mode, sensor_group, height_km)
run_meta = struct();
run_outputs = local_getfield_or(context, 'run_outputs', repmat(struct(), 0, 1));
if isempty(run_outputs) || ~isfinite(height_km)
    return;
end

semantic_mode = string(semantic_mode);
sensor_group = string(sensor_group);
for idx_out = 1:numel(run_outputs)
    out = run_outputs(idx_out);
    if semantic_mode == "comparison"
        continue;
    end
    if string(local_getfield_or(out, 'mode', "")) ~= semantic_mode
        continue;
    end
    run_output = local_getfield_or(out, 'run_output', struct());
    if string(local_getfield_or(local_getfield_or(run_output, 'sensor_group', struct()), 'name', "")) ~= sensor_group
        continue;
    end
    runs = local_getfield_or(run_output, 'runs', repmat(struct(), 0, 1));
    for idx_run = 1:numel(runs)
        if local_getfield_or(runs(idx_run), 'h_km', NaN) == height_km
            run_meta = local_build_run_metadata(run_output, runs(idx_run));
            return;
        end
    end
end

if semantic_mode == "comparison"
    legacy_meta = local_lookup_run_metadata(context, "legacyDG", sensor_group, height_km);
    closed_meta = local_lookup_run_metadata(context, "closedD", sensor_group, height_km);
    if isempty(fieldnames(legacy_meta)) && isempty(fieldnames(closed_meta))
        return;
    end
    run_meta = local_merge_comparison_metadata(legacy_meta, closed_meta);
end
end

function run_meta = local_build_run_metadata(run_output, run)
effective_domain = local_getfield_or(local_getfield_or(run, 'expansion_state', struct()), 'effective_search_domain', struct());
if isempty(fieldnames(effective_domain))
    effective_domain = struct( ...
        'ns_search_min', local_min_table_value(local_getfield_or(run, 'design_table', table()), 'Ns'), ...
        'ns_search_max', local_max_table_value(local_getfield_or(run, 'design_table', table()), 'Ns'), ...
        'ns_search_step', local_min_spacing(local_getfield_or(run, 'design_table', table()), 'Ns'), ...
        'P_grid', local_unique_table_values(local_getfield_or(run, 'design_table', table()), 'P'), ...
        'T_grid', local_unique_table_values(local_getfield_or(run, 'design_table', table()), 'T'));
end
diag = local_getfield_or(local_getfield_or(run, 'expansion_state', struct()), 'diagnostics', struct());
frontier_row = local_getfield_or(diag, 'frontier_row', struct());
boundary_row = local_getfield_or(diag, 'boundary_row', struct());
incremental_history = local_getfield_or(run, 'incremental_search_history', table());
last_stop_reason = "";
if istable(incremental_history) && ~isempty(incremental_history) && ismember('stop_reason', incremental_history.Properties.VariableNames)
    last_stop_reason = string(incremental_history.stop_reason(end));
end

run_meta = struct();
run_meta.snapshot_stage = "expanded_final";
if ~istable(local_getfield_or(run, 'incremental_search_history', table())) || isempty(local_getfield_or(run, 'incremental_search_history', table()))
    run_meta.snapshot_stage = "initial";
end
run_meta.search_domain_ns = [local_getfield_or(effective_domain, 'ns_search_min', NaN), local_getfield_or(effective_domain, 'ns_search_max', NaN), local_getfield_or(effective_domain, 'ns_search_step', NaN)];
run_meta.search_domain_p = reshape(local_getfield_or(effective_domain, 'P_grid', []), 1, []);
run_meta.search_domain_t = reshape(local_getfield_or(effective_domain, 'T_grid', []), 1, []);
options = local_getfield_or(run_output, 'options', struct());
options_search_domain = local_getfield_or(options, 'search_domain', struct());
run_meta.expand_enabled = logical(local_getfield_or(options, 'Ns_allow_expand', local_getfield_or(options_search_domain, 'Ns_allow_expand', false)));
run_meta.expand_blocks = local_getfield_or(options, 'Ns_expand_blocks', local_getfield_or(options_search_domain, 'Ns_expand_blocks', []));
run_meta.ns_hard_max = local_getfield_or(options, 'Ns_hard_max', local_getfield_or(options_search_domain, 'Ns_hard_max', NaN));
run_meta.expansion_stop_reason = string(local_getfield_or(local_getfield_or(run, 'expansion_state', struct()), 'stop_reason', last_stop_reason));
run_meta.boundary_hit_detected = logical(local_getfield_or(boundary_row, 'is_boundary_dominated', false) | local_getfield_or(boundary_row, 'search_upper_bound_likely_insufficient', false));
run_meta.frontier_defined_ratio = local_getfield_or(frontier_row, 'frontier_defined_ratio_over_inclinations', NaN);
end

function metadata = local_merge_run_metadata(metadata, run_meta)
if isempty(fieldnames(run_meta))
    return;
end
metadata.snapshot_stage = string(local_getfield_or(run_meta, 'snapshot_stage', metadata.snapshot_stage));
metadata.search_domain_ns = local_stringify(local_getfield_or(run_meta, 'search_domain_ns', metadata.search_domain_ns));
metadata.search_domain_p = local_stringify(local_getfield_or(run_meta, 'search_domain_p', metadata.search_domain_p));
metadata.search_domain_t = local_stringify(local_getfield_or(run_meta, 'search_domain_t', metadata.search_domain_t));
metadata.expand_enabled = logical(local_getfield_or(run_meta, 'expand_enabled', metadata.expand_enabled));
metadata.expand_blocks = local_expand_blocks_text(local_getfield_or(run_meta, 'expand_blocks', metadata.expand_blocks));
metadata.ns_hard_max = local_getfield_or(run_meta, 'ns_hard_max', metadata.ns_hard_max);
metadata.expansion_stop_reason = string(local_getfield_or(run_meta, 'expansion_stop_reason', metadata.expansion_stop_reason));
metadata.boundary_hit_detected = logical(local_getfield_or(run_meta, 'boundary_hit_detected', metadata.boundary_hit_detected));
metadata.frontier_defined_ratio = local_getfield_or(run_meta, 'frontier_defined_ratio', metadata.frontier_defined_ratio);
end

function comparison_meta = local_merge_comparison_metadata(legacy_meta, closed_meta)
comparison_meta = struct();
comparison_meta.snapshot_stage = "expanded_final";
comparison_meta.search_domain_ns = [ ...
    max([local_first_num(legacy_meta, 'search_domain_ns', 1), local_first_num(closed_meta, 'search_domain_ns', 1)]), ...
    min([local_first_num(legacy_meta, 'search_domain_ns', 2), local_first_num(closed_meta, 'search_domain_ns', 2)]), ...
    local_non_nan_min([local_first_num(legacy_meta, 'search_domain_ns', 3), local_first_num(closed_meta, 'search_domain_ns', 3)])];
comparison_meta.search_domain_p = local_longer_vector(local_getfield_or(legacy_meta, 'search_domain_p', []), local_getfield_or(closed_meta, 'search_domain_p', []));
comparison_meta.search_domain_t = local_longer_vector(local_getfield_or(legacy_meta, 'search_domain_t', []), local_getfield_or(closed_meta, 'search_domain_t', []));
comparison_meta.expand_enabled = logical(local_getfield_or(legacy_meta, 'expand_enabled', false) || local_getfield_or(closed_meta, 'expand_enabled', false));
comparison_meta.expand_blocks = local_expand_blocks_text({local_getfield_or(legacy_meta, 'expand_blocks', ""), local_getfield_or(closed_meta, 'expand_blocks', "")});
comparison_meta.ns_hard_max = max([local_getfield_or(legacy_meta, 'ns_hard_max', NaN), local_getfield_or(closed_meta, 'ns_hard_max', NaN)], [], 'omitnan');
comparison_meta.expansion_stop_reason = "legacyDG=" + string(local_getfield_or(legacy_meta, 'expansion_stop_reason', "")) + "; closedD=" + string(local_getfield_or(closed_meta, 'expansion_stop_reason', ""));
comparison_meta.boundary_hit_detected = logical(local_getfield_or(legacy_meta, 'boundary_hit_detected', false) || local_getfield_or(closed_meta, 'boundary_hit_detected', false));
comparison_meta.frontier_defined_ratio = local_non_nan_min([local_getfield_or(legacy_meta, 'frontier_defined_ratio', NaN), local_getfield_or(closed_meta, 'frontier_defined_ratio', NaN)]);
end

function local_write_metadata_sidecar(file_path, metadata)
sidecar_path = local_sidecar_path(file_path);
payload = metadata;
payload.file_path = string(file_path);
payload.generated_at = string(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH:mm:ss Z'));
fid = fopen(sidecar_path, 'w');
if fid < 0
    warning('MB:MetadataSidecar', 'Failed to open metadata sidecar for writing: %s', sidecar_path);
    return;
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', jsonencode(payload));
end

function path_out = local_sidecar_path(file_path)
[folder, stem] = fileparts(file_path);
path_out = fullfile(folder, stem + ".meta.json");
end

function txt = local_expand_blocks_text(blocks)
if isempty(blocks)
    txt = "";
    return;
end
if ischar(blocks) || isstring(blocks)
    txt = strjoin(string(blocks), '; ');
    return;
end
if iscell(blocks)
    parts = strings(numel(blocks), 1);
    for idx = 1:numel(blocks)
        parts(idx) = local_expand_blocks_text(blocks{idx});
    end
    txt = strjoin(parts(strlength(parts) > 0), '; ');
    return;
end
if isstruct(blocks)
    parts = strings(numel(blocks), 1);
    for idx = 1:numel(blocks)
        block = blocks(idx);
        name = string(local_getfield_or(block, 'name', "block" + idx));
        if isfield(block, 'ns_values') && ~isempty(block.ns_values)
            vals = reshape(block.ns_values, 1, []);
            parts(idx) = name + "[" + vals(1) + ":" + local_non_nan_min(diff(vals)) + ":" + vals(end) + "]";
        else
            parts(idx) = name + "[" + local_getfield_or(block, 'ns_min', NaN) + ":" + local_getfield_or(block, 'ns_step', NaN) + ":" + local_getfield_or(block, 'ns_max', NaN) + "]";
        end
    end
    txt = strjoin(parts(strlength(parts) > 0), '; ');
    return;
end
txt = local_stringify(blocks);
end

function values = local_unique_table_values(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    values = [];
    return;
end
values = unique(reshape(T.(field_name), 1, []), 'sorted');
end

function value = local_min_table_value(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
data = T.(field_name);
data = data(isfinite(data));
if isempty(data)
    value = NaN;
else
    value = min(data);
end
end

function value = local_max_table_value(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
data = T.(field_name);
data = data(isfinite(data));
if isempty(data)
    value = NaN;
else
    value = max(data);
end
end

function value = local_min_spacing(T, field_name)
values = local_unique_table_values(T, field_name);
if numel(values) < 2
    value = NaN;
else
    diffs = diff(values);
    diffs = diffs(diffs > 0);
    if isempty(diffs)
        value = NaN;
    else
        value = min(diffs);
    end
end
end

function value = local_first_num(S, field_name, idx)
candidate = local_getfield_or(S, field_name, [NaN NaN NaN]);
if numel(candidate) < idx
    value = NaN;
else
    value = candidate(idx);
end
end

function value = local_non_nan_min(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function out = local_longer_vector(a, b)
if numel(b) > numel(a)
    out = b;
else
    out = a;
end
end
