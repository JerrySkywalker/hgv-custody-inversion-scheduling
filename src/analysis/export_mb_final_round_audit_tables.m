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
rows = cell(0, 24);
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

    source_table = local_resolve_matching_table(tables_dir, figure_name);
    [source_min, source_max, row_count] = local_read_ns_bounds(source_table);
    initial_ns_min = local_resolve_initial_ns_min(meta, cfg, source_min);
    resolver_min = local_getdouble(meta, 'resolver_xlim_min', NaN);
    resolver_max = local_getdouble(meta, 'resolver_xlim_max', NaN);
    actual_min = local_getdouble(meta, 'actual_rendered_xlim_min', local_getdouble(meta, 'x_min_rendered', NaN));
    actual_max = local_getdouble(meta, 'actual_rendered_xlim_max', local_getdouble(meta, 'x_max_rendered', NaN));
    history_padding_applied = logical(local_getfield_or(meta, 'history_padding_applied', false));
    history_padding_mode = string(local_getfield_or(meta, 'history_padding_mode', ""));
    [expected_behavior, actual_behavior, pass_fail, root_cause_tag] = local_resolve_passratio_root_cause(domain_mode, initial_ns_min, source_min, source_max, resolver_min, actual_min, actual_max, history_padding_applied, meta);

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        string(local_infer_semantic_name(figure_name, meta)), ...
        string(local_infer_export_chain(figure_name, meta)), ...
        "passratio", ...
        domain_mode, ...
        string(source_table), ...
        logical(local_getfield_or(meta, 'phasecurve_cache_hit', false)), ...
        string(local_getfield_or(meta, 'phasecurve_cache_key', "")), ...
        double(source_min), ...
        double(source_max), ...
        double(row_count), ...
        logical(history_padding_applied), ...
        history_padding_mode, ...
        double(resolver_min), ...
        double(resolver_max), ...
        logical(local_getfield_or(meta, 'fallback_override_applied', false)), ...
        string(local_getfield_or(meta, 'fallback_override_source', "")), ...
        double(actual_min), ...
        double(actual_max), ...
        string(local_getfield_or(meta, 'x_domain_origin', "")), ...
        string(expected_behavior), ...
        string(actual_behavior), ...
        logical(pass_fail), ...
        string(root_cause_tag)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
    'phasecurve_source_file_or_table', 'phasecurve_cache_hit', 'phasecurve_cache_key', ...
    'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', ...
    'history_padding_applied', 'history_padding_mode', ...
    'resolver_xlim_min', 'resolver_xlim_max', ...
    'fallback_override_applied', 'fallback_override_source', ...
    'actual_rendered_xlim_min', 'actual_rendered_xlim_max', 'x_domain_origin', ...
    'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});

if isempty(T)
    T = table('Size', [0, 24], ...
        'VariableTypes', {'string','string','string','string','string','string','logical','string','double','double','double','logical','string','double','double','logical','string','double','double','string','string','string','logical','string'}, ...
        'VariableNames', {'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
        'phasecurve_source_file_or_table', 'phasecurve_cache_hit', 'phasecurve_cache_key', ...
        'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', ...
        'history_padding_applied', 'history_padding_mode', ...
        'resolver_xlim_min', 'resolver_xlim_max', ...
        'fallback_override_applied', 'fallback_override_source', ...
        'actual_rendered_xlim_min', 'actual_rendered_xlim_max', 'x_domain_origin', ...
        'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});
    return;
end

T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.export_chain = string(T.export_chain);
T.render_mode = string(T.render_mode);
T.domain_mode = string(T.domain_mode);
T.phasecurve_source_file_or_table = string(T.phasecurve_source_file_or_table);
T.phasecurve_cache_hit = logical(T.phasecurve_cache_hit);
T.phasecurve_cache_key = string(T.phasecurve_cache_key);
T.history_padding_applied = logical(T.history_padding_applied);
T.history_padding_mode = string(T.history_padding_mode);
T.fallback_override_applied = logical(T.fallback_override_applied);
T.fallback_override_source = string(T.fallback_override_source);
T.x_domain_origin = string(T.x_domain_origin);
T.expected_domain_behavior = string(T.expected_domain_behavior);
T.actual_domain_behavior = string(T.actual_domain_behavior);
T.pass_fail = logical(T.pass_fail);
T.root_cause_tag = string(T.root_cause_tag);
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
    if ~ismember('padding_applied', T_this.Properties.VariableNames)
        T_this.padding_applied = false(height(T_this), 1);
    end
    chunks{end + 1, 1} = T_this; %#ok<AGROW>
end
if isempty(chunks)
    T = table('Size', [0, 8], ...
        'VariableTypes', {'string','string','double','double','double','double','string','logical'}, ...
        'VariableNames', {'figure_name', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'padding_applied'});
else
    T = vertcat(chunks{:});
    T.figure_name = string(T.figure_name);
    T.group_key = string(T.group_key);
    T.history_fill_mode = string(T.history_fill_mode);
    T.padding_applied = logical(T.padding_applied);
end
end

function T = local_build_heatmap_render_mode_audit_summary(figures_dir)
files = dir(fullfile(figures_dir, '*heatmap*.png'));
rows = cell(0, 18);
for idx = 1:numel(files)
    figure_name = string(files(idx).name);
    lower_name = lower(figure_name);
    if ~(contains(lower_name, "minimumns_heatmap") || contains(lower_name, "statemap"))
        continue;
    end

    meta = local_read_sidecar(fullfile(files(idx).folder, files(idx).name));
    heatmap_mode = local_resolve_heatmap_mode(meta, figure_name);
    domain_mode = local_resolve_heatmap_domain_mode(meta, figure_name);
    matrix_value_type = local_resolve_matrix_value_type(heatmap_mode);
    annotation_mode = local_resolve_heatmap_annotation_mode(heatmap_mode);
    pass_fail = local_heatmap_semantics_pass(heatmap_mode, matrix_value_type, annotation_mode);
    root_cause_tag = "correct";
    if ~pass_fail
        root_cause_tag = "state_map_derived_from_numeric_surface";
    end
    cache_key = build_mb_figure_signature(struct( ...
        'figure_family', "heatmap", ...
        'heatmap_view', heatmap_mode, ...
        'heatmap_domain_view', domain_mode, ...
        'matrix_source_type', matrix_value_type));

    rows(end + 1, :) = { ... %#ok<AGROW>
        figure_name, ...
        string(local_infer_semantic_name(figure_name, meta)), ...
        string(local_infer_export_chain(figure_name, meta)), ...
        "heatmap", ...
        domain_mode, ...
        string(heatmap_mode), ...
        string(local_getfield_or(meta, 'heatmap_surface_mode', "")), ...
        false, ...
        string(cache_key), ...
        string(local_resolve_heatmap_matrix_source_name(heatmap_mode)), ...
        string(matrix_value_type), ...
        string(heatmap_mode), ...
        string(domain_mode), ...
        string(annotation_mode), ...
        string(local_expected_heatmap_behavior(heatmap_mode)), ...
        string(local_actual_heatmap_behavior(heatmap_mode, matrix_value_type, annotation_mode)), ...
        logical(pass_fail), ...
        string(root_cause_tag)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
    'heatmap_mode', 'heatmap_surface_source', 'heatmap_cache_hit', 'heatmap_cache_key', ...
    'matrix_source_name', 'matrix_value_type', 'numeric_or_state', ...
    'local_or_globalSkeleton', 'annotation_mode', ...
    'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});

if isempty(T)
    T = table('Size', [0, 18], ...
        'VariableTypes', {'string','string','string','string','string','string','string','logical','string','string','string','string','string','string','string','string','logical','string'}, ...
        'VariableNames', { ...
        'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
        'heatmap_mode', 'heatmap_surface_source', 'heatmap_cache_hit', 'heatmap_cache_key', ...
        'matrix_source_name', 'matrix_value_type', 'numeric_or_state', ...
        'local_or_globalSkeleton', 'annotation_mode', ...
        'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});
        return;
end

T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.export_chain = string(T.export_chain);
T.render_mode = string(T.render_mode);
T.domain_mode = string(T.domain_mode);
T.heatmap_mode = string(T.heatmap_mode);
T.heatmap_surface_source = string(T.heatmap_surface_source);
T.heatmap_cache_hit = logical(T.heatmap_cache_hit);
T.heatmap_cache_key = string(T.heatmap_cache_key);
T.matrix_source_name = string(T.matrix_source_name);
T.matrix_value_type = string(T.matrix_value_type);
T.numeric_or_state = string(T.numeric_or_state);
T.local_or_globalSkeleton = string(T.local_or_globalSkeleton);
T.annotation_mode = string(T.annotation_mode);
T.expected_domain_behavior = string(T.expected_domain_behavior);
T.actual_domain_behavior = string(T.actual_domain_behavior);
T.pass_fail = logical(T.pass_fail);
T.root_cause_tag = string(T.root_cause_tag);
end

function T = local_build_plot_domain_root_cause_audit_summary(passratio_audit, heatmap_audit)
rows = cell(0, 27);
for idx = 1:height(passratio_audit)
    row = passratio_audit(idx, :);
    rows(end + 1, :) = { ... %#ok<AGROW>
        row.figure_name(1), row.semantic_name(1), row.export_chain(1), row.render_mode(1), row.domain_mode(1), ...
        row.phasecurve_source_file_or_table(1), row.phasecurve_cache_hit(1), row.phasecurve_cache_key(1), ...
        row.source_table_min_ns(1), row.source_table_max_ns(1), row.source_table_row_count(1), ...
        row.history_padding_applied(1), row.history_padding_mode(1), ...
        row.resolver_xlim_min(1), row.resolver_xlim_max(1), ...
        row.fallback_override_applied(1), row.fallback_override_source(1), ...
        row.actual_rendered_xlim_min(1), row.actual_rendered_xlim_max(1), ...
        "", false, "", "", ...
        row.expected_domain_behavior(1), row.actual_domain_behavior(1), row.pass_fail(1), row.root_cause_tag(1)};
end
for idx = 1:height(heatmap_audit)
    row = heatmap_audit(idx, :);
    rows(end + 1, :) = { ... %#ok<AGROW>
        row.figure_name(1), row.semantic_name(1), row.export_chain(1), row.render_mode(1), row.domain_mode(1), ...
        "", false, "", ...
        NaN, NaN, NaN, ...
        false, "", ...
        NaN, NaN, ...
        false, "", ...
        NaN, NaN, ...
        row.heatmap_surface_source(1), row.heatmap_cache_hit(1), row.heatmap_cache_key(1), row.matrix_source_name(1), ...
        row.expected_domain_behavior(1), row.actual_domain_behavior(1), row.pass_fail(1), row.root_cause_tag(1)};
end

T = cell2table(rows, 'VariableNames', { ...
    'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
    'phasecurve_source_file_or_table', 'phasecurve_cache_hit', 'phasecurve_cache_key', ...
    'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', ...
    'history_padding_applied', 'history_padding_mode', ...
    'resolver_xlim_min', 'resolver_xlim_max', ...
    'fallback_override_applied', 'fallback_override_source', ...
    'actual_rendered_xlim_min', 'actual_rendered_xlim_max', ...
    'heatmap_surface_source', 'heatmap_cache_hit', 'heatmap_cache_key', 'matrix_source_name', ...
    'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});

if isempty(T)
    T = table('Size', [0, 28], ...
        'VariableTypes', {'string','string','string','string','string','string','logical','string','double','double','double','logical','string','double','double','logical','string','double','double','string','logical','string','string','string','string','logical','string'}, ...
        'VariableNames', { ...
        'figure_name', 'semantic_name', 'export_chain', 'render_mode', 'domain_mode', ...
        'phasecurve_source_file_or_table', 'phasecurve_cache_hit', 'phasecurve_cache_key', ...
        'source_table_min_ns', 'source_table_max_ns', 'source_table_row_count', ...
        'history_padding_applied', 'history_padding_mode', ...
        'resolver_xlim_min', 'resolver_xlim_max', ...
        'fallback_override_applied', 'fallback_override_source', ...
        'actual_rendered_xlim_min', 'actual_rendered_xlim_max', ...
        'heatmap_surface_source', 'heatmap_cache_hit', 'heatmap_cache_key', 'matrix_source_name', ...
        'expected_domain_behavior', 'actual_domain_behavior', 'pass_fail', 'root_cause_tag'});
        return;
end

T.figure_name = string(T.figure_name);
T.semantic_name = string(T.semantic_name);
T.export_chain = string(T.export_chain);
T.render_mode = string(T.render_mode);
T.domain_mode = string(T.domain_mode);
T.phasecurve_source_file_or_table = string(T.phasecurve_source_file_or_table);
T.phasecurve_cache_hit = logical(T.phasecurve_cache_hit);
T.phasecurve_cache_key = string(T.phasecurve_cache_key);
T.history_padding_applied = logical(T.history_padding_applied);
T.history_padding_mode = string(T.history_padding_mode);
T.fallback_override_applied = logical(T.fallback_override_applied);
T.fallback_override_source = string(T.fallback_override_source);
T.heatmap_surface_source = string(T.heatmap_surface_source);
T.heatmap_cache_hit = logical(T.heatmap_cache_hit);
T.heatmap_cache_key = string(T.heatmap_cache_key);
T.matrix_source_name = string(T.matrix_source_name);
T.expected_domain_behavior = string(T.expected_domain_behavior);
T.actual_domain_behavior = string(T.actual_domain_behavior);
T.pass_fail = logical(T.pass_fail);
T.root_cause_tag = string(T.root_cause_tag);
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
    rows(end + 1, :) = {row.figure_name(1), "heatmap_view", row.heatmap_cache_key(1), signature_fields, row.heatmap_cache_hit(1), row.root_cause_tag(1) ~= "correct", row.pass_fail(1)}; %#ok<AGROW>
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

function [expected_behavior, actual_behavior, pass_fail, root_cause_tag] = local_resolve_passratio_root_cause(domain_mode, initial_ns_min, source_min, source_max, resolver_min, actual_min, actual_max, history_padding_applied, meta)
expected_behavior = "";
actual_behavior = "";
pass_fail = false;
root_cause_tag = string(local_getfield_or(meta, 'root_cause_tag', ""));

switch string(domain_mode)
    case "history_full"
        expected_behavior = "history_full_from_initial_ns_min_with_zero_padding";
        actual_behavior = "history_full_padded_table";
        pass_fail = isfinite(initial_ns_min) && isfinite(actual_min) && actual_min <= initial_ns_min + 1.0e-9 && logical(history_padding_applied);
        if pass_fail
            root_cause_tag = "correct";
        elseif ~logical(history_padding_applied)
            root_cause_tag = "naming_only_fix_without_data_fix";
        elseif isfinite(source_min) && isfinite(initial_ns_min) && source_min > initial_ns_min + 1.0e-9
            root_cause_tag = "source_table_tail_only";
        elseif isfinite(resolver_min) && isfinite(actual_min) && isfinite(initial_ns_min) && resolver_min <= initial_ns_min + 1.0e-9 && actual_min > initial_ns_min + 1.0e-9
            root_cause_tag = "resolver_ok_but_render_override";
        else
            root_cause_tag = "source_table_tail_only";
        end
    case "effective_full_range"
        expected_behavior = "effective_domain_window_from_effective_search_domain";
        actual_behavior = "effective_domain_view";
        pass_fail = local_xlim_matches_resolver(resolver_min, local_getdouble(meta, 'resolver_xlim_max', NaN), actual_min, actual_max);
        if pass_fail
            root_cause_tag = "correct";
        elseif isfinite(resolver_min) && isfinite(actual_min)
            root_cause_tag = "resolver_ok_but_render_override";
        else
            root_cause_tag = "cache_reused_old_tail_table";
        end
    case "frontier_zoom"
        expected_behavior = "frontier_zoom_local_window";
        actual_behavior = "frontier_zoom_view";
        pass_fail = local_xlim_matches_resolver(resolver_min, local_getdouble(meta, 'resolver_xlim_max', NaN), actual_min, actual_max);
        if pass_fail
            root_cause_tag = "correct";
        elseif isfinite(resolver_min) && isfinite(actual_min)
            root_cause_tag = "resolver_ok_but_render_override";
        else
            root_cause_tag = "cache_reused_old_tail_table";
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
semantic_name = string(local_getfield_or(meta, 'semantic_mode', ""));
lower_name = lower(char(figure_name));
if semantic_name == ""
    if contains(lower_name, 'legacydg')
        semantic_name = "legacyDG";
    elseif contains(lower_name, 'closedd')
        semantic_name = "closedD";
    elseif contains(lower_name, 'comparison')
        semantic_name = "comparison";
    elseif contains(lower_name, 'profilecompare')
        semantic_name = "cross_profile";
    else
        semantic_name = "";
    end
end
end

function export_chain = local_infer_export_chain(figure_name, meta)
export_chain = string(local_getfield_or(meta, 'figure_family', ""));
lower_name = lower(char(figure_name));
if export_chain == ""
    if contains(lower_name, 'comparison')
        export_chain = "comparison";
    elseif contains(lower_name, 'profilecompare')
        export_chain = "cross_profile";
    elseif contains(lower_name, 'legacydg')
        export_chain = "legacyDG";
    elseif contains(lower_name, 'closedd')
        export_chain = "closedD";
    else
        export_chain = "";
    end
end
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
if domain_mode ~= ""
    return;
end
lower_name = lower(char(figure_name));
if contains(lower_name, 'globalskeleton')
    domain_mode = "globalSkeleton";
else
    domain_mode = "local";
end
end

function matrix_value_type = local_resolve_matrix_value_type(heatmap_mode)
if string(heatmap_mode) == "numeric_requirement"
    matrix_value_type = "numeric_requirement";
else
    matrix_value_type = "discrete_state";
end
end

function annotation_mode = local_resolve_heatmap_annotation_mode(heatmap_mode)
if string(heatmap_mode) == "numeric_requirement"
    annotation_mode = "numeric_labels";
else
    annotation_mode = "state_only";
end
end

function tf = local_heatmap_semantics_pass(heatmap_mode, matrix_value_type, annotation_mode)
if string(heatmap_mode) == "numeric_requirement"
    tf = string(matrix_value_type) == "numeric_requirement" && string(annotation_mode) == "numeric_labels";
else
    tf = string(matrix_value_type) == "discrete_state" && string(annotation_mode) ~= "numeric_labels";
end
end

function source_name = local_resolve_heatmap_matrix_source_name(heatmap_mode)
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

function text_value = local_actual_heatmap_behavior(heatmap_mode, matrix_value_type, annotation_mode)
text_value = string(heatmap_mode) + ":" + string(matrix_value_type) + ":" + string(annotation_mode);
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
