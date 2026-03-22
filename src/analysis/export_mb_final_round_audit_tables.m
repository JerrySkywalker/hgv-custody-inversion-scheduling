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
history_padding = local_build_passratio_history_padding_summary(tables_dir);
heatmap_audit = local_build_heatmap_render_mode_audit_summary(figures_dir);
root_cause_audit = local_build_plot_domain_root_cause_audit_summary(passratio_audit, heatmap_audit);
cache_semantics = local_build_plot_cache_domain_semantics_audit(passratio_audit, heatmap_audit);
consistency_audit = local_build_semantic_domain_consistency_summary(passratio_audit);

passratio_csv = fullfile(tables_dir, 'passratio_plot_domain_audit_summary.csv');
padding_csv = fullfile(tables_dir, 'passratio_history_padding_summary.csv');
heatmap_csv = fullfile(tables_dir, 'heatmap_render_mode_audit_summary.csv');
root_cause_csv = fullfile(tables_dir, 'plot_domain_root_cause_audit_summary.csv');
cache_csv = fullfile(tables_dir, 'plot_cache_domain_semantics_audit.csv');
consistency_csv = fullfile(tables_dir, 'semantic_domain_consistency_summary.csv');

milestone_common_save_table(passratio_audit, passratio_csv);
milestone_common_save_table(history_padding, padding_csv);
milestone_common_save_table(heatmap_audit, heatmap_csv);
milestone_common_save_table(root_cause_audit, root_cause_csv);
milestone_common_save_table(cache_semantics, cache_csv);
milestone_common_save_table(consistency_audit, consistency_csv);

artifacts = struct();
artifacts.passratio_plot_domain_audit_csv = string(passratio_csv);
artifacts.passratio_history_padding_csv = string(padding_csv);
artifacts.heatmap_render_mode_audit_csv = string(heatmap_csv);
artifacts.plot_domain_root_cause_audit_csv = string(root_cause_csv);
artifacts.plot_cache_domain_semantics_audit_csv = string(cache_csv);
artifacts.semantic_domain_consistency_csv = string(consistency_csv);
end

function T = local_build_passratio_plot_domain_audit_summary(figures_dir, tables_dir, cfg)
files = dir(fullfile(figures_dir, '*passratio*.png'));
rows = cell(0, 31);
for idx = 1:numel(files)
    figure_name = string(files(idx).name);
    lower_name = lower(figure_name);
    if ~(contains(lower_name, "historyfull") || contains(lower_name, "effectivefullrange") || contains(lower_name, "frontierzoom"))
        continue;
    end

    meta = local_read_sidecar(fullfile(files(idx).folder, files(idx).name));
    domain_mode = string(local_getfield_or(meta, 'plot_domain_mode', ""));
    if ~ismember(domain_mode, ["history_full", "effective_full_range", "frontier_zoom"])
        continue;
    end

    export_chain = string(local_infer_export_chain(figure_name, meta));
    semantic_name = string(local_infer_semantic_name(figure_name, meta));
    height_km = double(local_resolve_height_km(meta));
    source_table = local_resolve_source_table(meta, tables_dir, figure_name);
    source_table_name = string(local_basename(source_table));
    source_min = local_getdouble(meta, 'source_table_min_ns', NaN);
    source_max = local_getdouble(meta, 'source_table_max_ns', NaN);
    row_count = local_getdouble(meta, 'source_table_row_count', NaN);
    if ~(isfinite(source_min) && isfinite(source_max) && isfinite(row_count))
        [source_min, source_max, row_count] = local_read_ns_bounds(source_table);
    end
    initial_ns_min = local_resolve_initial_ns_min(meta, cfg, source_min);
    history_origin_mode = string(local_getfield_or(meta, 'history_origin', ""));
    if domain_mode == "history_full" && history_origin_mode == ""
        history_origin_mode = "initial_ns_min";
    end
    history_origin_min = local_resolve_history_origin_min(history_origin_mode, initial_ns_min);
    resolver_min = local_getdouble(meta, 'resolver_xlim_min', NaN);
    resolver_max = local_getdouble(meta, 'resolver_xlim_max', NaN);
    actual_min = local_getdouble(meta, 'actual_rendered_xlim_min', local_getdouble(meta, 'x_min_rendered', NaN));
    actual_max = local_getdouble(meta, 'actual_rendered_xlim_max', local_getdouble(meta, 'x_max_rendered', NaN));
    history_padding_applied = logical(local_getfield_or(meta, 'history_padding_applied', false));
    history_padding_mode = string(local_getfield_or(meta, 'history_padding_mode', ""));
    source_table_is_tail_only = isfinite(source_min) && isfinite(history_origin_min) && source_min > history_origin_min + 1.0e-9;
    cache_hit = logical(local_getfield_or(meta, 'phasecurve_cache_hit', false));
    cache_key = string(local_getfield_or(meta, 'phasecurve_cache_key', ""));
    fallback_override_applied = logical(local_getfield_or(meta, 'fallback_override_applied', false));
    fallback_override_source = string(local_getfield_or(meta, 'fallback_override_source', ""));
    [expected_behavior, actual_behavior, pass_fail, root_cause_tag] = local_resolve_passratio_root_cause( ...
        domain_mode, export_chain, source_table_is_tail_only, resolver_min, resolver_max, actual_min, actual_max, ...
        history_padding_applied, history_origin_mode, history_origin_min, cache_hit, fallback_override_applied, meta);
    stale_domain_semantics_reused = cache_hit && ismember(root_cause_tag, ["cache_reused_old_tail_table", "comparison_still_using_tail_gap_table"]);

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        semantic_name, ...
        double(height_km), ...
        export_chain, ...
        "passratio", ...
        domain_mode, ...
        source_table_name, ...
        string(source_table), ...
        double(source_min), ...
        double(source_max), ...
        double(row_count), ...
        logical(source_table_is_tail_only), ...
        logical(cache_hit), ...
        cache_key, ...
        logical(cache_hit), ...
        cache_key, ...
        logical(stale_domain_semantics_reused), ...
        logical(history_padding_applied), ...
        history_padding_mode, ...
        history_origin_mode, ...
        double(resolver_min), ...
        double(resolver_max), ...
        logical(fallback_override_applied), ...
        fallback_override_source, ...
        double(actual_min), ...
        double(actual_max), ...
        string(local_getfield_or(meta, 'x_domain_origin', "")), ...
        string(expected_behavior), ...
        string(actual_behavior), ...
        logical(pass_fail), ...
        string(root_cause_tag)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', 'semantic_name', 'height_km', 'export_chain', 'render_mode', 'domain_mode', ...
    'source_table_name', 'phasecurve_source_file_or_table', ...
    'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', 'source_table_is_tail_only', ...
    'cache_hit', 'cache_key', 'phasecurve_cache_hit', 'phasecurve_cache_key', 'stale_domain_semantics_reused', ...
    'history_padding_applied', 'history_padding_mode', 'history_origin_mode', ...
    'resolver_xlim_min', 'resolver_xlim_max', ...
    'fallback_override_applied', 'fallback_override_source', ...
    'actual_rendered_xlim_min', 'actual_rendered_xlim_max', 'x_domain_origin', ...
    'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});

if isempty(T)
    T = table('Size', [0, 31], ...
        'VariableTypes', {'string','string','double','string','string','string','string','string','double','double','double','logical','logical','string','logical','string','logical','logical','string','string','double','double','logical','string','double','double','string','string','string','logical','string'}, ...
        'VariableNames', {'figure_name', 'semantic_name', 'height_km', 'export_chain', 'render_mode', 'domain_mode', ...
        'source_table_name', 'phasecurve_source_file_or_table', ...
        'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', 'source_table_is_tail_only', ...
        'cache_hit', 'cache_key', 'phasecurve_cache_hit', 'phasecurve_cache_key', 'stale_domain_semantics_reused', ...
        'history_padding_applied', 'history_padding_mode', 'history_origin_mode', ...
        'resolver_xlim_min', 'resolver_xlim_max', ...
        'fallback_override_applied', 'fallback_override_source', ...
        'actual_rendered_xlim_min', 'actual_rendered_xlim_max', 'x_domain_origin', ...
        'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});
    return;
end

T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.height_km = double(T.height_km);
T.export_chain = string(T.export_chain);
T.render_mode = string(T.render_mode);
T.domain_mode = string(T.domain_mode);
T.source_table_name = string(T.source_table_name);
T.phasecurve_source_file_or_table = string(T.phasecurve_source_file_or_table);
T.source_table_is_tail_only = logical(T.source_table_is_tail_only);
T.cache_hit = logical(T.cache_hit);
T.cache_key = string(T.cache_key);
T.phasecurve_cache_hit = logical(T.phasecurve_cache_hit);
T.phasecurve_cache_key = string(T.phasecurve_cache_key);
T.stale_domain_semantics_reused = logical(T.stale_domain_semantics_reused);
T.history_padding_applied = logical(T.history_padding_applied);
T.history_padding_mode = string(T.history_padding_mode);
T.history_origin_mode = string(T.history_origin_mode);
T.fallback_override_applied = logical(T.fallback_override_applied);
T.fallback_override_source = string(T.fallback_override_source);
T.x_domain_origin = string(T.x_domain_origin);
T.expected_domain_behavior = string(T.expected_domain_behavior);
T.actual_domain_behavior = string(T.actual_domain_behavior);
T.pass_fail = logical(T.pass_fail);
T.root_cause_tag = string(T.root_cause_tag);
if ~isempty(T)
    T = sortrows(T, {'height_km', 'export_chain', 'semantic_name', 'domain_mode', 'figure_name'});
end
end

function T = local_build_passratio_history_padding_summary(tables_dir)
files = dir(fullfile(tables_dir, '*historyPadding*.csv'));
chunks = cell(0, 1);
for idx = 1:numel(files)
    file_path = fullfile(files(idx).folder, files(idx).name);
    T_this = readtable(file_path, 'TextType', 'string');
    if ~ismember('figure_name', T_this.Properties.VariableNames)
        T_this.figure_name = repmat(string(strrep(files(idx).name, '.csv', '.png')), height(T_this), 1);
    end
    if ~ismember('height_km', T_this.Properties.VariableNames)
        T_this.height_km = NaN(height(T_this), 1);
    end
    if ~ismember('history_origin_mode', T_this.Properties.VariableNames)
        T_this.history_origin_mode = repmat("", height(T_this), 1);
    end
    if ~ismember('history_padding_applied', T_this.Properties.VariableNames)
        T_this.history_padding_applied = false(height(T_this), 1);
    end
    if ~ismember('padding_applied', T_this.Properties.VariableNames)
        T_this.padding_applied = T_this.history_padding_applied;
    end
    if ~ismember('pass_fail', T_this.Properties.VariableNames)
        T_this.pass_fail = false(height(T_this), 1);
    end
    chunks{end + 1, 1} = T_this; %#ok<AGROW>
end
if isempty(chunks)
    T = table('Size', [0, 12], ...
        'VariableTypes', {'string','double','string','double','double','double','double','string','string','logical','logical','logical'}, ...
        'VariableNames', {'figure_name', 'height_km', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'history_origin_mode', 'history_padding_applied', 'padding_applied', 'pass_fail'});
else
    T = vertcat(chunks{:});
    T.figure_name = string(T.figure_name);
    T.height_km = double(T.height_km);
    T.group_key = string(T.group_key);
    T.history_fill_mode = string(T.history_fill_mode);
    T.history_origin_mode = string(T.history_origin_mode);
    T.history_padding_applied = logical(T.history_padding_applied);
    T.padding_applied = logical(T.padding_applied);
    T.pass_fail = logical(T.pass_fail);
end
end

function T = local_build_heatmap_render_mode_audit_summary(figures_dir)
files = dir(fullfile(figures_dir, '*heatmap*.png'));
rows = cell(0, 19);
for idx = 1:numel(files)
    figure_name = string(files(idx).name);
    lower_name = lower(figure_name);
    if ~(contains(lower_name, "minimumns_heatmap") || contains(lower_name, "statemap"))
        continue;
    end

    meta = local_read_sidecar(fullfile(files(idx).folder, files(idx).name));
    height_km = double(local_resolve_height_km_with_figure(meta, figure_name));
    heatmap_mode = local_resolve_heatmap_mode(meta, figure_name);
    domain_mode = local_resolve_heatmap_domain_mode(meta, figure_name);
    matrix_source_name = string(local_resolve_heatmap_matrix_source_name(meta, heatmap_mode));
    matrix_value_type = local_resolve_matrix_value_type(meta, heatmap_mode);
    uses_discrete_state_matrix = logical(local_getfield_or(meta, 'uses_discrete_state_matrix', heatmap_mode == "state_map"));
    uses_numeric_requirement_matrix = logical(local_getfield_or(meta, 'uses_numeric_requirement_matrix', heatmap_mode == "numeric_requirement"));
    annotation_mode = local_resolve_heatmap_annotation_mode(meta, heatmap_mode);
    [pass_fail, root_cause_tag] = local_heatmap_semantics_pass( ...
        heatmap_mode, domain_mode, matrix_source_name, matrix_value_type, uses_discrete_state_matrix, uses_numeric_requirement_matrix, annotation_mode);
    cache_hit = logical(local_getfield_or(meta, 'cache_hit', local_getfield_or(meta, 'heatmap_cache_hit', false)));
    cache_key = string(local_getfield_or(meta, 'cache_key', local_getfield_or(meta, 'heatmap_cache_key', "")));
    cache_key = build_mb_figure_signature(struct( ...
        'figure_family', "heatmap", ...
        'heatmap_view', heatmap_mode, ...
        'heatmap_domain_view', domain_mode, ...
        'matrix_source_type', matrix_value_type));
    if strlength(string(local_getfield_or(meta, 'heatmap_cache_key', ""))) > 0
        cache_key = string(local_getfield_or(meta, 'heatmap_cache_key', ""));
    end

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        string(local_infer_semantic_name(figure_name, meta)), ...
        string(local_infer_export_chain(figure_name, meta)), ...
        double(height_km), ...
        "heatmap", ...
        domain_mode, ...
        string(heatmap_mode), ...
        string(local_getfield_or(meta, 'heatmap_surface_source', local_getfield_or(meta, 'heatmap_surface_mode', ""))), ...
        logical(cache_hit), ...
        string(cache_key), ...
        matrix_source_name, ...
        string(matrix_value_type), ...
        logical(uses_discrete_state_matrix), ...
        logical(uses_numeric_requirement_matrix), ...
        string(annotation_mode), ...
        string(local_expected_heatmap_behavior(heatmap_mode)), ...
        string(local_actual_heatmap_behavior(heatmap_mode, domain_mode, matrix_source_name, matrix_value_type, annotation_mode)), ...
        logical(pass_fail), ...
        string(root_cause_tag)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', 'semantic_name', 'export_chain', 'height_km', 'render_mode', 'domain_mode', ...
    'heatmap_mode', 'heatmap_surface_source', 'cache_hit', 'cache_key', ...
    'matrix_source_name', 'matrix_value_type', 'uses_discrete_state_matrix', 'uses_numeric_requirement_matrix', 'annotation_mode', ...
    'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});

if isempty(T)
    T = table('Size', [0, 19], ...
        'VariableTypes', {'string','string','string','double','string','string','string','string','logical','string','string','string','logical','logical','string','string','string','logical','string'}, ...
        'VariableNames', { ...
        'figure_name', 'semantic_name', 'export_chain', 'height_km', 'render_mode', 'domain_mode', ...
        'heatmap_mode', 'heatmap_surface_source', 'cache_hit', 'cache_key', ...
        'matrix_source_name', 'matrix_value_type', 'uses_discrete_state_matrix', 'uses_numeric_requirement_matrix', 'annotation_mode', ...
        'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});
        return;
end

T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.export_chain = string(T.export_chain);
T.height_km = double(T.height_km);
T.render_mode = string(T.render_mode);
T.domain_mode = string(T.domain_mode);
T.heatmap_mode = string(T.heatmap_mode);
T.heatmap_surface_source = string(T.heatmap_surface_source);
T.cache_hit = logical(T.cache_hit);
T.cache_key = string(T.cache_key);
T.matrix_source_name = string(T.matrix_source_name);
T.matrix_value_type = string(T.matrix_value_type);
T.uses_discrete_state_matrix = logical(T.uses_discrete_state_matrix);
T.uses_numeric_requirement_matrix = logical(T.uses_numeric_requirement_matrix);
T.annotation_mode = string(T.annotation_mode);
T.expected_domain_behavior = string(T.expected_domain_behavior);
T.actual_domain_behavior = string(T.actual_domain_behavior);
T.pass_fail = logical(T.pass_fail);
T.root_cause_tag = string(T.root_cause_tag);
end

function T = local_build_plot_domain_root_cause_audit_summary(passratio_audit, ~)
if isempty(passratio_audit)
    T = table('Size', [0, 24], ...
        'VariableTypes', {'string','string','double','string','string','string','double','double','double','logical','double','double','double','double','logical','string','logical','string','logical','logical','string','string','string','logical'}, ...
        'VariableNames', {'figure_name', 'semantic_name', 'height_km', 'domain_mode', 'export_chain', ...
        'source_table_name', 'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', 'source_table_is_tail_only', ...
        'resolver_xlim_min', 'resolver_xlim_max', 'actual_rendered_xlim_min', 'actual_rendered_xlim_max', ...
        'fallback_override_applied', 'fallback_override_source', 'cache_hit', 'cache_key', 'stale_domain_semantics_reused', ...
        'history_padding_applied', 'history_padding_mode', 'history_origin_mode', 'root_cause_tag', 'pass_fail'});
    return;
end

T = passratio_audit(:, {'figure_name', 'semantic_name', 'height_km', 'domain_mode', 'export_chain', ...
    'source_table_name', 'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', 'source_table_is_tail_only', ...
    'resolver_xlim_min', 'resolver_xlim_max', 'actual_rendered_xlim_min', 'actual_rendered_xlim_max', ...
    'fallback_override_applied', 'fallback_override_source', 'cache_hit', 'cache_key', 'stale_domain_semantics_reused', ...
    'history_padding_applied', 'history_padding_mode', 'history_origin_mode', 'root_cause_tag', 'pass_fail'});
T = sortrows(T, {'height_km', 'export_chain', 'semantic_name', 'domain_mode', 'figure_name'});
end

function T = local_build_plot_cache_domain_semantics_audit(passratio_audit, heatmap_audit)
rows = cell(0, 7);
for idx = 1:height(passratio_audit)
    row = passratio_audit(idx, :);
    signature_fields = "domain_view=" + row.domain_mode + ";history_padding=" + string(row.history_padding_applied) + ";fill=" + row.history_padding_mode;
    rows(end + 1, :) = {row.figure_name(1), "passratio_view", row.phasecurve_cache_key(1), signature_fields, row.phasecurve_cache_hit(1), row.root_cause_tag(1) ~= "correct", row.pass_fail(1)}; %#ok<AGROW>
end
for idx = 1:height(heatmap_audit)
    row = heatmap_audit(idx, :);
    signature_fields = "heatmap_view=" + row.heatmap_mode + ";domain_view=" + row.domain_mode + ";matrix=" + row.matrix_value_type;
    rows(end + 1, :) = {row.figure_name(1), "heatmap_view", row.cache_key(1), signature_fields, row.cache_hit(1), row.root_cause_tag(1) ~= "correct", row.pass_fail(1)}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'artifact_name', 'cache_type', 'cache_key', 'semantic_signature_fields', 'cache_hit', 'reused_old_domain_semantics', 'pass_fail'});
if isempty(T)
    T = table('Size', [0, 7], ...
        'VariableTypes', {'string','string','string','string','logical','logical','logical'}, ...
        'VariableNames', {'artifact_name', 'cache_type', 'cache_key', 'semantic_signature_fields', 'cache_hit', 'reused_old_domain_semantics', 'pass_fail'});
    return;
end
T.artifact_name = string(T.artifact_name);
T.cache_type = string(T.cache_type);
T.cache_key = string(T.cache_key);
T.semantic_signature_fields = string(T.semantic_signature_fields);
T.cache_hit = logical(T.cache_hit);
T.reused_old_domain_semantics = logical(T.reused_old_domain_semantics);
T.pass_fail = logical(T.pass_fail);
end

function T = local_build_semantic_domain_consistency_summary(passratio_audit)
if isempty(passratio_audit)
    T = table('Size', [0, 8], ...
        'VariableTypes', {'string','string','double','double','double','double','double','logical'}, ...
        'VariableNames', {'semantic_name', 'figure_name', 'search_domain_min', 'effective_domain_min', 'history_domain_min', 'rendered_xlim_min', 'rendered_xlim_max', 'consistency_pass'});
    return;
end

rows = cell(height(passratio_audit), 8);
group_keys = arrayfun(@local_passratio_group_key, passratio_audit.figure_name);
for idx = 1:height(passratio_audit)
    row = passratio_audit(idx, :);
    group_key = group_keys(idx);
    group_mask = group_keys == group_key;
    group_rows = passratio_audit(group_mask, :);
    history_row = group_rows(group_rows.domain_mode == "history_full", :);
    effective_row = group_rows(group_rows.domain_mode == "effective_full_range", :);
    if isempty(history_row)
        history_min = NaN;
    else
        history_min = history_row.actual_rendered_xlim_min(1);
    end
    if isempty(effective_row)
        effective_min = NaN;
        search_min = row.source_table_min_ns;
    else
        effective_min = effective_row.actual_rendered_xlim_min(1);
        search_min = effective_row.actual_rendered_xlim_min(1);
    end
    rows(idx, :) = { ...
        row.semantic_name(1), ...
        row.figure_name(1), ...
        double(search_min), ...
        double(effective_min), ...
        double(history_min), ...
        row.actual_rendered_xlim_min(1), ...
        row.actual_rendered_xlim_max(1), ...
        row.pass_fail(1)};
end
T = cell2table(rows, 'VariableNames', {'semantic_name', 'figure_name', 'search_domain_min', 'effective_domain_min', 'history_domain_min', 'rendered_xlim_min', 'rendered_xlim_max', 'consistency_pass'});
T.semantic_name = string(T.semantic_name);
T.figure_name = string(T.figure_name);
T.consistency_pass = logical(T.consistency_pass);
end

function key = local_passratio_group_key(figure_name)
key = string(figure_name);
key = replace(key, "_historyFull_", "_");
key = replace(key, "_effectiveFullRange_", "_");
key = replace(key, "_frontierZoom_", "_");
end

function [expected_behavior, actual_behavior, pass_fail, root_cause_tag] = local_resolve_passratio_root_cause(domain_mode, export_chain, source_table_is_tail_only, resolver_min, resolver_max, actual_min, actual_max, history_padding_applied, history_origin_mode, history_origin_min, cache_hit, fallback_override_applied, meta)
expected_behavior = "";
actual_behavior = "";
pass_fail = false;
root_cause_tag = string(local_getfield_or(meta, 'root_cause_tag', ""));

switch string(domain_mode)
    case "history_full"
        expected_behavior = "history_full_from_initial_ns_min_with_zero_padding";
        actual_behavior = "history_full_padded_table";
        pass_fail = isfinite(history_origin_min) && isfinite(actual_min) && actual_min <= history_origin_min + 1.0e-9 && logical(history_padding_applied);
        if history_origin_mode == "zero"
            pass_fail = pass_fail && abs(actual_min) < 1.0e-9;
        end
        if pass_fail
            root_cause_tag = "correct";
        elseif cache_hit && source_table_is_tail_only && ~logical(history_padding_applied)
            root_cause_tag = "cache_reused_old_tail_table";
        elseif source_table_is_tail_only && ~logical(history_padding_applied) && ismember(string(export_chain), ["comparison", "cross_profile"])
            root_cause_tag = "comparison_still_using_tail_gap_table";
        elseif ~logical(history_padding_applied)
            root_cause_tag = "history_padding_missing";
        elseif logical(fallback_override_applied) || ...
                (isfinite(resolver_min) && isfinite(actual_min) && isfinite(history_origin_min) && resolver_min <= history_origin_min + 1.0e-9 && actual_min > history_origin_min + 1.0e-9)
            root_cause_tag = "resolver_ok_but_render_override";
        elseif source_table_is_tail_only
            root_cause_tag = "source_table_tail_only";
        else
            root_cause_tag = "history_padding_missing";
        end
    case "effective_full_range"
        expected_behavior = "effective_domain_window_from_effective_search_domain";
        actual_behavior = "effective_domain_view";
        pass_fail = local_xlim_matches_resolver(resolver_min, resolver_max, actual_min, actual_max);
        if pass_fail
            root_cause_tag = "correct";
        elseif logical(fallback_override_applied) || (isfinite(resolver_min) && isfinite(actual_min))
            root_cause_tag = "resolver_ok_but_render_override";
        elseif cache_hit && source_table_is_tail_only
            root_cause_tag = "cache_reused_old_tail_table";
        else
            root_cause_tag = "source_table_tail_only";
        end
    case "frontier_zoom"
        expected_behavior = "frontier_zoom_local_window";
        actual_behavior = "frontier_zoom_view";
        pass_fail = local_xlim_matches_resolver(resolver_min, resolver_max, actual_min, actual_max);
        if pass_fail
            root_cause_tag = "correct";
        elseif logical(fallback_override_applied) || (isfinite(resolver_min) && isfinite(actual_min))
            root_cause_tag = "resolver_ok_but_render_override";
        elseif cache_hit && source_table_is_tail_only
            root_cause_tag = "cache_reused_old_tail_table";
        else
            root_cause_tag = "source_table_tail_only";
        end
end
end

function tf = local_xlim_matches_resolver(resolver_min, resolver_max, actual_min, actual_max)
tf = all(isfinite([resolver_min, resolver_max, actual_min, actual_max])) && ...
    abs(actual_min - resolver_min) < 1.0e-9 && abs(actual_max - resolver_max) < 1.0e-9;
end

function source_table = local_resolve_matching_table(tables_dir, figure_name)
source_table = fullfile(tables_dir, char(erase(string(figure_name), ".png") + ".csv"));
if exist(source_table, 'file') ~= 2
    source_table = "";
end
end

function [min_ns, max_ns, row_count] = local_read_ns_bounds(source_table)
min_ns = NaN;
max_ns = NaN;
row_count = NaN;
if strlength(string(source_table)) == 0 || exist(char(source_table), 'file') ~= 2
    return;
end
T = readtable(char(source_table), 'TextType', 'string');
row_count = height(T);
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

function initial_min = local_resolve_initial_ns_min(meta, cfg, fallback)
initial_min = fallback;
profile_name = string(local_getfield_or(meta, 'search_profile', ""));
if profile_name == ""
    return;
end
try
    profile = get_mb_search_profile(profile_name, cfg);
    range = local_getfield_or(profile, 'Ns_initial_range', []);
    if isnumeric(range) && ~isempty(range) && isfinite(range(1))
        initial_min = double(range(1));
    end
catch
    initial_min = fallback;
end
end

function semantic_name = local_infer_semantic_name(figure_name, meta)
lower_name = lower(char(figure_name));
if contains(lower_name, 'profilecompare_legacydg')
    semantic_name = "legacyDG";
elseif contains(lower_name, 'profilecompare_closedd')
    semantic_name = "closedD";
elseif contains(lower_name, 'legacydg')
    semantic_name = "legacyDG";
elseif contains(lower_name, 'closedd')
    semantic_name = "closedD";
elseif contains(lower_name, 'comparison')
    semantic_name = "comparison";
else
    semantic_name = string(local_getfield_or(meta, 'semantic_mode', ""));
end
end

function export_chain = local_infer_export_chain(figure_name, meta)
lower_name = lower(char(figure_name));
if contains(lower_name, 'profilecompare')
    export_chain = "cross_profile";
elseif contains(lower_name, 'comparison')
    export_chain = "comparison";
elseif contains(lower_name, 'legacydg')
    export_chain = "legacyDG";
elseif contains(lower_name, 'closedd')
    export_chain = "closedD";
else
    export_chain = string(local_getfield_or(meta, 'figure_family', ""));
end
end

function source_table = local_resolve_source_table(meta, tables_dir, figure_name)
source_table = string(local_getfield_or(meta, 'phasecurve_source_file_or_table', ""));
if strlength(source_table) ~= 0
    return;
end
source_table = string(local_resolve_matching_table(tables_dir, figure_name));
end

function value = local_resolve_height_km(meta)
value = local_getdouble(meta, 'height_km', NaN);
if ~isfinite(value)
    value = local_getdouble(meta, 'h_km', NaN);
end
end

function value = local_resolve_height_km_with_figure(meta, figure_name)
value = local_resolve_height_km(meta);
if isfinite(value)
    return;
end
tokens = regexp(char(figure_name), '_h(\d+)', 'tokens', 'once');
if isempty(tokens)
    value = NaN;
else
    value = str2double(tokens{1});
end
end

function history_origin_min = local_resolve_history_origin_min(history_origin_mode, initial_ns_min)
if string(history_origin_mode) == "zero"
    history_origin_min = 0;
else
    history_origin_min = initial_ns_min;
end
end

function name = local_basename(path_value)
name = "";
if strlength(string(path_value)) == 0
    return;
end
[~, stem, ext] = fileparts(char(path_value));
name = string(stem) + string(ext);
end

function heatmap_mode = local_resolve_heatmap_mode(meta, figure_name)
heatmap_mode = string(local_getfield_or(meta, 'heatmap_mode', ""));
if heatmap_mode ~= ""
    return;
end
semantics = string(local_getfield_or(meta, 'heatmap_value_semantics', ""));
lower_name = lower(char(figure_name));
if semantics == "minimum_feasible_ns" || contains(lower_name, 'minimumns_heatmap')
    heatmap_mode = "numeric_requirement";
else
    heatmap_mode = "state_map";
end
end

function domain_mode = local_resolve_heatmap_domain_mode(meta, figure_name)
domain_mode = string(local_getfield_or(meta, 'heatmap_surface_mode', ""));
domain_mode = local_normalize_heatmap_domain_mode(domain_mode);
if domain_mode ~= ""
    return;
end
lower_name = lower(char(figure_name));
if contains(lower_name, 'globalskeleton')
    domain_mode = "globalSkeleton";
else
    domain_mode = "local";
end

function domain_mode = local_normalize_heatmap_domain_mode(domain_mode)
domain_mode = string(domain_mode);
switch lower(char(domain_mode))
    case 'global_skeleton'
        domain_mode = "globalSkeleton";
    case 'local_defined_surface'
        domain_mode = "local";
end
end
end

function matrix_value_type = local_resolve_matrix_value_type(meta, heatmap_mode)
matrix_value_type = string(local_getfield_or(meta, 'matrix_value_type', ""));
if matrix_value_type ~= ""
    return;
end
if string(heatmap_mode) == "numeric_requirement"
    matrix_value_type = "numeric_requirement";
else
    matrix_value_type = "discrete_state";
end
end

function annotation_mode = local_resolve_heatmap_annotation_mode(meta, heatmap_mode)
annotation_mode = string(local_getfield_or(meta, 'annotation_mode', ""));
if annotation_mode ~= ""
    return;
end
if string(heatmap_mode) == "numeric_requirement"
    annotation_mode = "numeric_labels";
else
    annotation_mode = "state_only";
end
end

function [tf, root_cause_tag] = local_heatmap_semantics_pass(heatmap_mode, domain_mode, matrix_source_name, matrix_value_type, uses_discrete_state_matrix, uses_numeric_requirement_matrix, annotation_mode)
root_cause_tag = "correct";
if string(heatmap_mode) == "numeric_requirement"
    tf = string(matrix_value_type) == "numeric_requirement" && logical(uses_numeric_requirement_matrix) && string(annotation_mode) == "numeric_labels";
    if ~tf
        root_cause_tag = "numeric_heatmap_semantics_mismatch";
    end
else
    tf = string(matrix_value_type) == "discrete_state" && logical(uses_discrete_state_matrix) && string(annotation_mode) ~= "numeric_labels";
    if ~tf
        root_cause_tag = "state_map_derived_from_numeric_surface";
    end
end
if tf && string(domain_mode) == "globalSkeleton" && ~contains(lower(string(matrix_source_name)), "global")
    tf = false;
    root_cause_tag = "global_skeleton_using_local_matrix_source";
end
end

function source_name = local_resolve_heatmap_matrix_source_name(meta, heatmap_mode)
source_name = string(local_getfield_or(meta, 'matrix_source_name', ""));
if source_name ~= ""
    return;
end
if string(heatmap_mode) == "numeric_requirement"
    source_name = "minimum_feasible_ns_matrix";
else
    source_name = "discrete_state_matrix";
end
end

function text_value = local_expected_heatmap_behavior(heatmap_mode)
if string(heatmap_mode) == "numeric_requirement"
    text_value = "numeric_requirement_surface_with_numeric_labels";
else
    text_value = "discrete_state_surface_without_numeric_labels";
end
end

function text_value = local_actual_heatmap_behavior(heatmap_mode, domain_mode, matrix_source_name, matrix_value_type, annotation_mode)
text_value = string(heatmap_mode) + ":" + string(domain_mode) + ":" + string(matrix_source_name) + ":" + string(matrix_value_type) + ":" + string(annotation_mode);
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
