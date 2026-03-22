function artifacts = export_mb_final_round_audit_tables(baseline_root)
%EXPORT_MB_FINAL_ROUND_AUDIT_TABLES Export final-round audit tables for MB figures.

if nargin < 1 || strlength(string(baseline_root)) == 0
    error('MB:FinalAudit:MissingRoot', 'baseline_root is required.');
end

baseline_root = char(string(baseline_root));
figures_dir = fullfile(baseline_root, 'figures');
tables_dir = fullfile(baseline_root, 'tables');
cfg = milestone_common_defaults();

passratio_audit = local_build_passratio_plot_domain_audit_summary(figures_dir, tables_dir, cfg);
passratio_csv = fullfile(tables_dir, 'passratio_plot_domain_audit_summary.csv');
milestone_common_save_table(passratio_audit, passratio_csv);

heatmap_audit = local_build_heatmap_render_mode_audit_summary(figures_dir);
heatmap_csv = fullfile(tables_dir, 'heatmap_render_mode_audit_summary.csv');
milestone_common_save_table(heatmap_audit, heatmap_csv);

consistency_audit = local_build_semantic_domain_consistency_summary(passratio_audit);
consistency_csv = fullfile(tables_dir, 'semantic_domain_consistency_summary.csv');
milestone_common_save_table(consistency_audit, consistency_csv);

artifacts = struct();
artifacts.passratio_plot_domain_audit_csv = string(passratio_csv);
artifacts.heatmap_render_mode_audit_csv = string(heatmap_csv);
artifacts.semantic_domain_consistency_csv = string(consistency_csv);
end

function T = local_build_passratio_plot_domain_audit_summary(figures_dir, tables_dir, cfg)
files = dir(fullfile(figures_dir, '*passratio*.png'));
rows = cell(0, 14);
for idx = 1:numel(files)
    figure_name = string(files(idx).name);
    lower_name = lower(figure_name);
    if ~(contains(lower_name, "historyfull") || contains(lower_name, "effectivefullrange") || contains(lower_name, "frontierzoom"))
        continue;
    end
    meta = local_read_sidecar(fullfile(files(idx).folder, files(idx).name));
    if ~isfield(meta, 'plot_domain_mode')
        continue;
    end
    domain_mode = string(local_getfield_or(meta, 'plot_domain_mode', ""));
    if ~ismember(domain_mode, ["history_full", "effective_full_range", "frontier_zoom"])
        continue;
    end

    semantic_name = local_infer_semantic_name(figure_name);
    if semantic_name == ""
        semantic_name = string(local_getfield_or(meta, 'semantic_mode', ""));
    end
    sensor_group = string(local_getfield_or(meta, 'sensor_group', ""));
    if sensor_group == ""
        sensor_group = local_infer_sensor_group(figure_name);
    end
    source_table = local_resolve_source_table_path(figure_name, tables_dir);
    [source_min, source_max] = local_read_ns_bounds(source_table);
    initial_min = local_resolve_initial_ns_min(meta, cfg);
    rendered_min = local_getdouble(meta, 'x_min_rendered', NaN);
    rendered_max = local_getdouble(meta, 'x_max_rendered', NaN);
    [expected_min, expected_max, fallback_flag] = local_expected_window(domain_mode, initial_min, source_min, source_max, rendered_min, rendered_max);

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        semantic_name, ...
        sensor_group, ...
        domain_mode, ...
        string(source_table), ...
        source_min, ...
        source_max, ...
        initial_min, ...
        expected_min, ...
        expected_max, ...
        rendered_min, ...
        rendered_max, ...
        string(local_getfield_or(meta, 'x_domain_origin', "")), ...
        logical(fallback_flag)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', ...
    'semantic_name', ...
    'sensor_group', ...
    'domain_mode', ...
    'source_table_path', ...
    'source_table_min_ns', ...
    'source_table_max_ns', ...
    'initial_ns_min', ...
    'resolved_xlim_min', ...
    'resolved_xlim_max', ...
    'rendered_xlim_min', ...
    'rendered_xlim_max', ...
    'x_domain_origin', ...
    'was_overridden_by_fallback'});

if isempty(T)
    T = local_empty_passratio_audit_table();
end

T.source_table_path = string(T.source_table_path);
T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.sensor_group = string(T.sensor_group);
T.domain_mode = string(T.domain_mode);
T.x_domain_origin = string(T.x_domain_origin);
T.was_overridden_by_fallback = logical(T.was_overridden_by_fallback);
end

function T = local_build_heatmap_render_mode_audit_summary(figures_dir)
files = dir(fullfile(figures_dir, '*heatmap*.png'));
rows = cell(0, 8);
for idx = 1:numel(files)
    figure_name = string(files(idx).name);
    if ~contains(lower(figure_name), "minimumns_heatmap") && ~contains(lower(figure_name), "statemap")
        continue;
    end
    meta = local_read_sidecar(fullfile(files(idx).folder, files(idx).name));
    semantics = string(local_getfield_or(meta, 'heatmap_value_semantics', ""));
    if semantics == ""
        continue;
    end

    if semantics == "minimum_feasible_ns"
        heatmap_mode = "numeric_requirement";
        matrix_source = "minimum_feasible_ns_matrix";
        uses_numeric_values = true;
        uses_discrete_states = false;
        annotation_mode = "defined_cells_numeric_labels";
    else
        heatmap_mode = "state_map";
        matrix_source = "discrete_state_matrix";
        uses_numeric_values = false;
        uses_discrete_states = true;
        annotation_mode = "none";
    end

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        heatmap_mode, ...
        string(local_getfield_or(meta, 'heatmap_surface_mode', "")), ...
        matrix_source, ...
        logical(uses_numeric_values), ...
        logical(uses_discrete_states), ...
        annotation_mode, ...
        string(local_getfield_or(meta, 'plot_domain_mode', ""))};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', ...
    'heatmap_mode', ...
    'domain_mode', ...
    'matrix_source', ...
    'uses_numeric_values', ...
    'uses_discrete_states', ...
    'annotation_mode', ...
    'plot_domain_mode'});

if isempty(T)
    T = local_empty_heatmap_audit_table();
end

T.figure_name = string(T.figure_name);
T.heatmap_mode = string(T.heatmap_mode);
T.domain_mode = string(T.domain_mode);
T.matrix_source = string(T.matrix_source);
T.annotation_mode = string(T.annotation_mode);
T.plot_domain_mode = string(T.plot_domain_mode);
T.uses_numeric_values = logical(T.uses_numeric_values);
T.uses_discrete_states = logical(T.uses_discrete_states);
end

function T = local_build_semantic_domain_consistency_summary(passratio_audit)
if isempty(passratio_audit)
    T = local_empty_domain_consistency_table();
    return;
end

rows = cell(height(passratio_audit), 8);
for idx = 1:height(passratio_audit)
    row = passratio_audit(idx, :);
    search_domain_min = row.initial_ns_min;
    effective_domain_min = row.source_table_min_ns;
    history_domain_min = row.initial_ns_min;
    consistency_pass = local_consistency_pass(row.domain_mode, search_domain_min, effective_domain_min, row.rendered_xlim_min, row.rendered_xlim_max, row.source_table_max_ns);
    rows(idx, :) = { ...
        row.semantic_name(1), ...
        row.figure_name(1), ...
        search_domain_min, ...
        effective_domain_min, ...
        history_domain_min, ...
        row.rendered_xlim_min(1), ...
        row.rendered_xlim_max(1), ...
        logical(consistency_pass)};
end

T = cell2table(rows, 'VariableNames', { ...
    'semantic_name', ...
    'figure_name', ...
    'search_domain_min', ...
    'effective_domain_min', ...
    'history_domain_min', ...
    'rendered_xlim_min', ...
    'rendered_xlim_max', ...
    'consistency_pass'});
T.semantic_name = string(T.semantic_name);
T.figure_name = string(T.figure_name);
T.consistency_pass = logical(T.consistency_pass);
end

function pass = local_consistency_pass(domain_mode, search_min, effective_min, rendered_min, rendered_max, source_max)
pass = false;
switch string(domain_mode)
    case "history_full"
        pass = isfinite(search_min) && isfinite(rendered_min) && rendered_min <= search_min;
    case "effective_full_range"
        pass = isfinite(effective_min) && isfinite(rendered_min) && abs(rendered_min - effective_min) < 1.0e-9;
    case "frontier_zoom"
        pass = isfinite(effective_min) && isfinite(source_max) && isfinite(rendered_min) && isfinite(rendered_max) && ...
            rendered_min >= effective_min && rendered_max <= source_max && rendered_min < rendered_max;
end
end

function source_table = local_resolve_source_table_path(figure_name, tables_dir)
stem = erase(string(figure_name), ".png");
tokens = ["_historyFull", "_effectiveFullRange", "_frontierZoom", "_fullRange", "_globalTrend"];
for idx = 1:numel(tokens)
    stem = replace(stem, tokens(idx), "");
end
source_table = fullfile(tables_dir, char(stem + ".csv"));
if exist(source_table, 'file') ~= 2
    source_table = "";
end
end

function [min_ns, max_ns] = local_read_ns_bounds(source_table)
min_ns = NaN;
max_ns = NaN;
if strlength(string(source_table)) == 0 || exist(char(source_table), 'file') ~= 2
    return;
end
T = readtable(char(source_table), 'TextType', 'string');
if ~ismember('Ns', T.Properties.VariableNames)
    return;
end
values = T.Ns(isfinite(T.Ns));
if isempty(values)
    return;
end
min_ns = min(values);
max_ns = max(values);
end

function initial_min = local_resolve_initial_ns_min(meta, cfg)
initial_min = NaN;
profile_name = string(local_getfield_or(meta, 'search_profile', ""));
if profile_name == ""
    return;
end
try
    profile = get_mb_search_profile(profile_name, cfg);
    range = local_getfield_or(profile, 'Ns_initial_range', []);
    if isnumeric(range) && numel(range) >= 1 && isfinite(range(1))
        initial_min = double(range(1));
    end
catch
    initial_min = NaN;
end
end

function semantic_name = local_infer_semantic_name(figure_name)
lower_name = lower(char(figure_name));
if contains(lower_name, 'legacydg')
    semantic_name = "legacyDG";
elseif contains(lower_name, 'closedd')
    semantic_name = "closedD";
elseif contains(lower_name, 'comparison')
    semantic_name = "comparison";
else
    semantic_name = "";
end
end

function sensor_group = local_infer_sensor_group(figure_name)
lower_name = lower(char(figure_name));
if contains(lower_name, 'baseline')
    sensor_group = "baseline";
elseif contains(lower_name, 'optimistic')
    sensor_group = "optimistic";
elseif contains(lower_name, 'robust')
    sensor_group = "robust";
else
    sensor_group = "";
end
end

function [expected_min, expected_max, fallback_flag] = local_expected_window(domain_mode, initial_min, source_min, source_max, rendered_min, rendered_max)
expected_min = rendered_min;
expected_max = rendered_max;
fallback_flag = false;
switch string(domain_mode)
    case "history_full"
        expected_min = initial_min;
        expected_max = source_max;
        fallback_flag = isfinite(initial_min) && isfinite(rendered_min) && rendered_min > initial_min;
    case "effective_full_range"
        expected_min = source_min;
        expected_max = source_max;
        fallback_flag = isfinite(source_min) && isfinite(rendered_min) && abs(rendered_min - source_min) > 1.0e-9;
    case "frontier_zoom"
        expected_min = rendered_min;
        expected_max = rendered_max;
        fallback_flag = isfinite(source_min) && isfinite(source_max) && isfinite(rendered_min) && isfinite(rendered_max) && ...
            rendered_min <= source_min && rendered_max >= source_max;
end
end

function meta = local_read_sidecar(file_path)
meta = struct();
[folder, stem, ~] = fileparts(file_path);
sidecar = fullfile(folder, stem + ".meta.json");
if exist(sidecar, 'file') ~= 2
    return;
end
try
    meta = jsondecode(fileread(sidecar));
catch
    meta = struct();
end
end

function value = local_getdouble(S, field_name, fallback)
value = fallback;
if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
    candidate = double(S.(field_name));
    if isscalar(candidate) && isfinite(candidate)
        value = candidate;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function T = local_empty_passratio_audit_table()
T = table('Size', [0, 14], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'string', 'logical'}, ...
    'VariableNames', {'figure_name', 'semantic_name', 'sensor_group', 'domain_mode', 'source_table_path', 'source_table_min_ns', 'source_table_max_ns', 'initial_ns_min', 'resolved_xlim_min', 'resolved_xlim_max', 'rendered_xlim_min', 'rendered_xlim_max', 'x_domain_origin', 'was_overridden_by_fallback'});
end

function T = local_empty_heatmap_audit_table()
T = table('Size', [0, 8], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'logical', 'logical', 'string', 'string'}, ...
    'VariableNames', {'figure_name', 'heatmap_mode', 'domain_mode', 'matrix_source', 'uses_numeric_values', 'uses_discrete_states', 'annotation_mode', 'plot_domain_mode'});
end

function T = local_empty_domain_consistency_table()
T = table('Size', [0, 8], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'logical'}, ...
    'VariableNames', {'semantic_name', 'figure_name', 'search_domain_min', 'effective_domain_min', 'history_domain_min', 'rendered_xlim_min', 'rendered_xlim_max', 'consistency_pass'});
end
