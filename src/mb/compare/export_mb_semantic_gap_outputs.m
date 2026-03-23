function artifacts = export_mb_semantic_gap_outputs(legacy_output, closed_output, paths, plot_options)
%EXPORT_MB_SEMANTIC_GAP_OUTPUTS Export comparison artifacts between legacyDG and closedD.

if nargin < 4 || isempty(plot_options)
    plot_options = struct();
end

comparison = build_semantic_gap_tables(legacy_output, closed_output);
sensor_group = char(string(comparison.sensor_group));
sensor_label = char(string(comparison.sensor_label));
plot_mode_profile = local_resolve_plot_mode_profile(plot_options);

artifacts = struct();
artifacts.tables = struct();
artifacts.figures = struct();
artifacts.summary = comparison.summary_table;

summary_csv = fullfile(paths.tables, sprintf('MB_comparison_gap_summary_%s.csv', sensor_group));
milestone_common_save_table(comparison.summary_table, summary_csv);
artifacts.tables.summary = string(summary_csv);

for idx = 1:numel(comparison.run_pairs)
    pair = comparison.run_pairs(idx);
    h_label = sprintf('h%d', round(pair.h_km));

    gap_csv = fullfile(paths.tables, sprintf('MB_comparison_gap_heatmap_iP_%s_%s.csv', h_label, sensor_group));
    pass_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_%s_%s.csv', h_label, sensor_group));
    pass_primary_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_primary_%s_%s.csv', h_label, sensor_group));
    pass_history_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_historyFull_%s_%s.csv', h_label, sensor_group));
    pass_effective_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_effectiveFullRange_%s_%s.csv', h_label, sensor_group));
    pass_zoom_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_frontierZoom_%s_%s.csv', h_label, sensor_group));
    pass_padding_csv = fullfile(paths.tables, sprintf('MB_comparison_passratio_overlay_historyPadding_%s_%s.csv', h_label, sensor_group));
    frontier_csv = fullfile(paths.tables, sprintf('MB_comparison_frontier_shift_%s_%s.csv', h_label, sensor_group));
    frontier_diag_csv = fullfile(paths.tables, sprintf('MB_comparison_frontier_diagnostic_%s_%s.csv', h_label, sensor_group));
    summary_context_csv = fullfile(paths.tables, sprintf('MB_comparison_summary_%s_%s.csv', h_label, sensor_group));
    export_grade_csv = fullfile(paths.tables, sprintf('MB_comparison_export_grade_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(pair.requirement_gap_table, gap_csv);
    milestone_common_save_table(pair.passratio_gap_table, pass_csv);
    milestone_common_save_table(pair.frontier_gap_table, frontier_csv);
    milestone_common_save_table(pair.frontier_diagnostic_table, frontier_diag_csv);

    diag_artifacts = export_mb_boundary_hit_outputs(struct( ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'frontier_truncation_table', pair.frontier_truncation_table), ...
        paths, sprintf('comparison_%s_%s', h_label, sensor_group));

    fig_gap = plot_semantic_gap_heatmap(pair.requirement_gap_table, pair.h_km, sensor_label, struct( ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    gap_png = fullfile(paths.figures, sprintf('MB_comparison_gap_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_gap, gap_png);
    close(fig_gap);

    pass_windows = resolve_mb_passratio_plot_windows(pair.passratio_gap_table, pair.search_domain, struct( ...
        'y_fields', ["max_pass_ratio_legacyDG"; "max_pass_ratio_closedD"]));
    semantic_view_spec = struct( ...
        'group_fields', {{'h_km', 'family_name', 'i_deg'}}, ...
        'value_fields', {{'max_pass_ratio'}}, ...
        'fill_values', struct('max_pass_ratio', 0), ...
        'history_fill_mode', "zero", ...
        'history_origin', "initial_ns_min", ...
        'resolver_options', struct('y_fields', "max_pass_ratio"));
    history_view_spec = semantic_view_spec;
    history_view_spec.domain_view = "history_full";
    history_view_spec.figure_name = sprintf('MB_comparison_passratio_overlay_historyFull_%s_%s.png', h_label, sensor_group);
    effective_view_spec = semantic_view_spec;
    effective_view_spec.domain_view = "effective_full_range";
    effective_view_spec.figure_name = sprintf('MB_comparison_passratio_overlay_effectiveFullRange_%s_%s.png', h_label, sensor_group);
    zoom_view_spec = semantic_view_spec;
    zoom_view_spec.domain_view = "frontier_zoom";
    zoom_view_spec.plot_window = pass_windows.frontier_zoom;
    zoom_view_spec.figure_name = sprintf('MB_comparison_passratio_overlay_frontierZoom_%s_%s.png', h_label, sensor_group);

    [legacy_history_source, ~, legacy_history_meta] = build_mb_passratio_domain_view(pair.legacy_passratio_table, pair.search_domain, history_view_spec);
    [closed_history_source, ~, closed_history_meta] = build_mb_passratio_domain_view(pair.closed_passratio_table, pair.search_domain, history_view_spec);
    pass_history_table = local_build_comparison_passratio_view_table(legacy_history_source, closed_history_source);
    pass_padding_summary = local_build_comparison_history_padding_summary(pass_history_table, pair.search_domain, sprintf('MB_comparison_passratio_overlay_historyFull_%s_%s.png', h_label, sensor_group));
    pass_history_meta = local_build_comparison_view_meta(pair.search_domain, pair.passratio_gap_table, pass_history_table, legacy_history_meta, closed_history_meta);

    [legacy_effective_source, ~, legacy_effective_meta] = build_mb_passratio_domain_view(pair.legacy_passratio_table, pair.search_domain, effective_view_spec);
    [closed_effective_source, ~, closed_effective_meta] = build_mb_passratio_domain_view(pair.closed_passratio_table, pair.search_domain, effective_view_spec);
    pass_effective_table = local_build_comparison_passratio_view_table(legacy_effective_source, closed_effective_source);
    pass_effective_meta = local_build_comparison_view_meta(pair.search_domain, pair.passratio_gap_table, pass_effective_table, legacy_effective_meta, closed_effective_meta);

    [legacy_zoom_source, ~, legacy_zoom_meta] = build_mb_passratio_domain_view(pair.legacy_passratio_table, pair.search_domain, zoom_view_spec);
    [closed_zoom_source, ~, closed_zoom_meta] = build_mb_passratio_domain_view(pair.closed_passratio_table, pair.search_domain, zoom_view_spec);
    pass_zoom_table = local_build_comparison_passratio_view_table(legacy_zoom_source, closed_zoom_source);
    pass_zoom_meta = local_build_comparison_view_meta(pair.search_domain, pair.passratio_gap_table, pass_zoom_table, legacy_zoom_meta, closed_zoom_meta);

    milestone_common_save_table(pass_history_table, pass_history_csv);
    milestone_common_save_table(pass_effective_table, pass_effective_csv);
    milestone_common_save_table(pass_zoom_table, pass_zoom_csv);
    milestone_common_save_table(pass_padding_summary, pass_padding_csv);

    fig_pass_history = plot_semantic_gap_passratio_curves(pass_history_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "history_full", ...
        'plot_domain_source', "history_full", ...
        'plot_xlim_ns', pass_windows.history_full, ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pass_history_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_historyFull_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_history, pass_history_png);
    write_mb_plot_domain_sidecar(pass_history_png, "history_full", "initial_search_domain_lower_bound", local_capture_axis_xlim(fig_pass_history), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_history, pass_history_table, pass_history_csv, "history_full", pass_windows.history_full, pass_history_meta, struct( ...
        'figure_family', "comparison_passratio", ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'primary_plot_mode', plot_mode_profile.comparison_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "historyFull", ...
        'is_primary_selection', plot_mode_profile.comparison_primary_mode == "historyFull", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "historyFull", ...
        'expected_domain_behavior', "history_full_from_initial_ns_min_with_zero_padding", ...
        'actual_domain_behavior', "history_full_padded_table")));
    close(fig_pass_history);

    fig_pass_effective = plot_semantic_gap_passratio_curves(pass_effective_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "effective_full_range", ...
        'plot_domain_source', "effective_full_range", ...
        'plot_xlim_ns', pass_windows.effective_full_range, ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pass_effective_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_effectiveFullRange_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, pass_effective_png);
    write_mb_plot_domain_sidecar(pass_effective_png, "effective_full_range", "effective_search_domain", local_capture_axis_xlim(fig_pass_effective), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_effective, pass_effective_table, pass_effective_csv, "effective_full_range", pass_windows.effective_full_range, pass_effective_meta, struct( ...
        'figure_family', "comparison_passratio", ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'primary_plot_mode', plot_mode_profile.comparison_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "effectiveFullRange", ...
        'is_primary_selection', plot_mode_profile.comparison_primary_mode == "effectiveFullRange", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "effectiveFullRange", ...
        'expected_domain_behavior', "effective_domain_only_without_history_padding", ...
        'actual_domain_behavior', "effective_domain_view")));
    close(fig_pass_effective);

    fig_pass_zoom = plot_semantic_gap_passratio_curves(pass_zoom_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "frontier_zoom", ...
        'plot_domain_source', "frontier_zoom", ...
        'plot_xlim_ns', pass_windows.frontier_zoom, ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pass_zoom_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_frontierZoom_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_zoom, pass_zoom_png);
    write_mb_plot_domain_sidecar(pass_zoom_png, "frontier_zoom", "frontier_zoom_window", local_capture_axis_xlim(fig_pass_zoom), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_zoom, pass_zoom_table, pass_zoom_csv, "frontier_zoom", pass_windows.frontier_zoom, pass_zoom_meta, struct( ...
        'figure_family', "comparison_passratio", ...
        'primary_plot_mode', plot_mode_profile.comparison_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "frontierZoom", ...
        'is_primary_selection', plot_mode_profile.comparison_primary_mode == "frontierZoom", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "frontierZoom", ...
        'expected_domain_behavior', "frontier_zoom_local_window", ...
        'actual_domain_behavior', "frontier_zoom_view")));
    close(fig_pass_zoom);

    pass_mode_files = struct( ...
        'historyFull', struct('csv', string(pass_history_csv), 'png', string(pass_history_png), 'table', pass_history_table), ...
        'effectiveFullRange', struct('csv', string(pass_effective_csv), 'png', string(pass_effective_png), 'table', pass_effective_table), ...
        'frontierZoom', struct('csv', string(pass_zoom_csv), 'png', string(pass_zoom_png), 'table', pass_zoom_table));
    primary_pass = pass_mode_files.(char(plot_mode_profile.comparison_primary_mode));
    milestone_common_save_table(primary_pass.table, pass_primary_csv);
    pass_primary_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_primary_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(pass_primary_png));
    pass_alias_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_fullRange_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(pass_alias_png));
    global_alias_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_globalTrend_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(global_alias_png));

    fig_frontier = plot_semantic_gap_frontier_shift(pair.frontier_gap_table, pair.h_km, sensor_label, struct( ...
        'frontier_truncation_table', pair.frontier_truncation_table, ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    frontier_png = fullfile(paths.figures, sprintf('MB_comparison_frontier_shift_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_frontier, frontier_png);
    close(fig_frontier);
    summary_context = local_summary_context_table(pair, struct( ...
        'history_full_rendered_min_ns', local_pick_x(local_capture_axis_xlim(fig_pass_history), 1), ...
        'effective_full_rendered_min_ns', local_pick_x(local_capture_axis_xlim(fig_pass_effective), 1), ...
        'frontier_zoom_rendered_min_ns', local_pick_x(local_capture_axis_xlim(fig_pass_zoom), 1), ...
        'history_padding_applied', logical(local_getfield_or(pass_history_meta, 'history_padding_applied', false)), ...
        'domain_consistency_pass', logical(local_pick_x(local_capture_axis_xlim(fig_pass_history), 1) <= local_getfield_or(pass_history_meta, 'initial_ns_min', NaN)), ...
        'primary_plot_mode', plot_mode_profile.comparison_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'canonical_figure_file', string(pass_primary_png)));
    milestone_common_save_table(summary_context, summary_context_csv);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_historyFull_%s', h_label))) = string(pass_history_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_effectiveFullRange_%s', h_label))) = string(pass_effective_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_frontierZoom_%s', h_label))) = string(pass_zoom_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_primary_%s', h_label))) = string(pass_primary_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_historyPadding_%s', h_label))) = string(pass_padding_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_diagnostic_%s', h_label))) = string(frontier_diag_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('summary_%s', h_label))) = string(summary_context_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('export_grade_%s', h_label))) = string(export_grade_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('boundary_hit_%s', h_label))) = diag_artifacts.boundary_hit_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_saturation_%s', h_label))) = diag_artifacts.passratio_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_truncation_%s', h_label))) = diag_artifacts.frontier_csv;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioHistory_%s', h_label))) = string(pass_history_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioEffective_%s', h_label))) = string(pass_effective_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioZoom_%s', h_label))) = string(pass_zoom_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioPrimary_%s', h_label))) = string(pass_primary_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_png);

    diagnostics = struct( ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'frontier_truncation_table', pair.frontier_truncation_table);
    export_grade_table = local_build_comparison_export_grade(pair, sensor_group, diagnostics, plot_options);
    milestone_common_save_table(export_grade_table, export_grade_csv);
    local_maybe_export_paper_ready(@() plot_semantic_gap_heatmap(pair.requirement_gap_table, pair.h_km, sensor_label, struct( ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_comparison_gap_heatmap_iP_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "comparison_heatmap", diagnostics, plot_options);
    local_maybe_export_paper_ready(@() plot_semantic_gap_passratio_curves(pass_effective_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "effective_full_range", ...
        'plot_xlim_ns', pass_windows.effective_full_range, ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_effectiveFullRange_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "comparison_passratio", diagnostics, plot_options);
    local_maybe_export_paper_ready(@() plot_semantic_gap_frontier_shift(pair.frontier_gap_table, pair.h_km, sensor_label, struct( ...
        'frontier_truncation_table', pair.frontier_truncation_table, ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_comparison_frontier_shift_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "comparison_frontier", diagnostics, plot_options);
end
end

function local_maybe_export_paper_ready(builder_fn, file_path, figure_family, diagnostics, plot_options)
if ~logical(local_getfield_or(plot_options, 'export_paper_ready', false))
    return;
end
guard = guard_mb_paper_ready_export(figure_family, diagnostics, local_getfield_or(plot_options, 'paper_ready_guardrail', struct()));
if ~guard.allowed
    warning('MB:PaperReadyGuard', '%s', char(guard.note));
    return;
end
fig = builder_fn();
milestone_common_save_figure(fig, file_path);
close(fig);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function summary_table = local_summary_context_table(pair, extra_fields)
if nargin < 2 || isempty(extra_fields)
    extra_fields = struct();
end
summary_table = struct2table(pair.summary);
summary_table = addvars(summary_table, ...
    repmat(pair.h_km, height(summary_table), 1), ...
    repmat(string(pair.family_name), height(summary_table), 1), ...
    'Before', 1, ...
    'NewVariableNames', {'h_km', 'family_name'});
extra_names = fieldnames(extra_fields);
for idx = 1:numel(extra_names)
    field_name = extra_names{idx};
    value = extra_fields.(field_name);
    if isstring(value) || ischar(value)
        column = repmat(string(value), height(summary_table), 1);
    elseif islogical(value)
        column = repmat(logical(value), height(summary_table), 1);
    else
        column = repmat(double(value), height(summary_table), 1);
    end
    if ismember(field_name, summary_table.Properties.VariableNames)
        summary_table.(field_name) = column;
    else
        summary_table = addvars(summary_table, column, 'After', width(summary_table), 'NewVariableNames', field_name);
    end
end
end

function export_grade_table = local_build_comparison_export_grade(pair, sensor_group, diagnostics, plot_options)
families = ["comparison_heatmap", "comparison_passratio", "comparison_frontier"];
figure_names = ["gap_heatmap", "passratio_overlay", "frontier_shift"];
rows = cell(numel(families), 10);
for idx = 1:numel(families)
    guard = guard_mb_paper_ready_export(families(idx), diagnostics, local_getfield_or(plot_options, 'paper_ready_guardrail', struct()));
    rows(idx, :) = {pair.h_km, string(sensor_group), string(pair.family_name), figure_names(idx), ...
        string(local_export_grade_from_guard(guard)), logical(guard.allowed), string(guard.status), string(guard.note), ...
        logical(local_getfield_or(guard, 'boundary_dominated', false)), logical(local_getfield_or(guard, 'right_unity_reached', false))};
end
export_grade_table = cell2table(rows, 'VariableNames', {'h_km', 'sensor_group', 'family_name', 'figure_family', ...
    'export_grade', 'paper_ready_allowed', 'guard_status', 'note', 'boundary_dominated', 'right_unity_reached'});
export_grade_table.h_km = double(export_grade_table.h_km);
export_grade_table.paper_ready_allowed = logical(export_grade_table.paper_ready_allowed);
export_grade_table.boundary_dominated = logical(export_grade_table.boundary_dominated);
export_grade_table.right_unity_reached = logical(export_grade_table.right_unity_reached);
end

function grade = local_export_grade_from_guard(guard)
if logical(local_getfield_or(guard, 'allowed', false))
    grade = "paper_candidate";
else
    grade = "diagnostic_only";
end
end

function xlim_values = local_capture_axis_xlim(fig)
xlim_values = capture_mb_primary_axes_xlim(fig);
end

function profile = local_resolve_plot_mode_profile(plot_options)
profile = resolve_mb_plot_mode_profile(local_getfield_or(plot_options, 'runtime', struct()));
if isfield(plot_options, 'plot_mode_profile') && isstruct(plot_options.plot_mode_profile)
    profile = plot_options.plot_mode_profile;
end
end

function local_copy_figure_with_sidecar(source_png, target_png)
source_png = char(string(source_png));
target_png = char(string(target_png));
if strcmpi(source_png, target_png)
    return;
end
copyfile(source_png, target_png);
[source_folder, source_stem, ~] = fileparts(source_png);
[target_folder, target_stem, ~] = fileparts(target_png);
source_meta = fullfile(source_folder, [source_stem, '.meta.json']);
target_meta = fullfile(target_folder, [target_stem, '.meta.json']);
if isfile(source_meta)
    copyfile(source_meta, target_meta);
end
end

function value = local_pick_x(xlim_values, idx_pick)
value = NaN;
if isnumeric(xlim_values) && numel(xlim_values) >= idx_pick && isfinite(xlim_values(idx_pick))
    value = xlim_values(idx_pick);
end
end

function view_table = local_build_comparison_passratio_view_table(legacy_table, closed_table)
legacy = legacy_table(:, intersect({'h_km', 'family_name', 'i_deg', 'Ns', 'max_pass_ratio', 'history_padded_row', 'history_fill_mode', 'history_origin'}, legacy_table.Properties.VariableNames, 'stable'));
closed = closed_table(:, intersect({'h_km', 'family_name', 'i_deg', 'Ns', 'max_pass_ratio', 'history_padded_row', 'history_fill_mode', 'history_origin'}, closed_table.Properties.VariableNames, 'stable'));

if ismember('max_pass_ratio', legacy.Properties.VariableNames)
    legacy = renamevars(legacy, 'max_pass_ratio', 'max_pass_ratio_legacyDG');
else
    legacy.max_pass_ratio_legacyDG = zeros(height(legacy), 1);
end
if ismember('history_padded_row', legacy.Properties.VariableNames)
    legacy = renamevars(legacy, 'history_padded_row', 'legacy_history_padded_row');
end

if ismember('max_pass_ratio', closed.Properties.VariableNames)
    closed = renamevars(closed, 'max_pass_ratio', 'max_pass_ratio_closedD');
else
    closed.max_pass_ratio_closedD = zeros(height(closed), 1);
end
if ismember('history_padded_row', closed.Properties.VariableNames)
    closed = renamevars(closed, 'history_padded_row', 'closed_history_padded_row');
end

view_table = outerjoin(legacy, closed, 'Keys', {'h_km', 'family_name', 'i_deg', 'Ns'}, 'MergeKeys', true, 'Type', 'full');
view_table.legacy_present = isfinite(view_table.max_pass_ratio_legacyDG);
view_table.closed_present = isfinite(view_table.max_pass_ratio_closedD);
view_table.max_pass_ratio_legacyDG = local_fill_missing_numeric(view_table.max_pass_ratio_legacyDG, 0);
view_table.max_pass_ratio_closedD = local_fill_missing_numeric(view_table.max_pass_ratio_closedD, 0);
view_table.passratio_gap = view_table.max_pass_ratio_closedD - view_table.max_pass_ratio_legacyDG;

if all(ismember({'legacy_history_padded_row', 'closed_history_padded_row'}, view_table.Properties.VariableNames))
    legacy_pad = local_fill_missing_logical(view_table.legacy_history_padded_row, true);
    closed_pad = local_fill_missing_logical(view_table.closed_history_padded_row, true);
    view_table.history_padded_row = legacy_pad & closed_pad;
    view_table.history_padding_applied = repmat(any(view_table.history_padded_row), height(view_table), 1);
    view_table.history_fill_mode = repmat(local_pick_first_nonempty_string(view_table, {'history_fill_mode_legacy', 'history_fill_mode_closed', 'history_fill_mode_x', 'history_fill_mode_y'}, "zero"), height(view_table), 1);
    view_table.history_origin = repmat(local_pick_first_nonempty_string(view_table, {'history_origin_legacy', 'history_origin_closed', 'history_origin_x', 'history_origin_y'}, "initial_ns_min"), height(view_table), 1);
end

view_table = sortrows(view_table, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
end

function summary_table = local_build_comparison_history_padding_summary(view_table, search_domain, figure_name)
if isempty(view_table)
    summary_table = table('Size', [0, 12], ...
        'VariableTypes', {'string','double','string','double','double','double','double','string','string','logical','logical','logical'}, ...
        'VariableNames', {'figure_name', 'height_km', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'history_origin_mode', 'history_padding_applied', 'padding_applied', 'pass_fail'});
    return;
end

group_rows = unique(view_table(:, {'h_km', 'family_name', 'i_deg'}), 'rows', 'stable');
rows = cell(height(group_rows), 12);
for idx = 1:height(group_rows)
    group_row = group_rows(idx, :);
    mask = view_table.h_km == group_row.h_km(1) & strcmp(string(view_table.family_name), string(group_row.family_name(1))) & view_table.i_deg == group_row.i_deg(1);
    sub = view_table(mask, :);
    padded_mask = false(height(sub), 1);
    if ismember('history_padded_row', sub.Properties.VariableNames)
        padded_mask = local_fill_missing_logical(sub.history_padded_row, false);
    end
    history_fill_mode = local_pick_first_nonempty_string(sub, {'history_fill_mode'}, "zero");
    history_origin_mode = local_pick_first_nonempty_string(sub, {'history_origin'}, "initial_ns_min");
    initial_ns_min = local_getfield_or(search_domain, 'history_ns_min', NaN);
    final_ns_max = local_getfield_or(search_domain, 'history_ns_max', local_getfield_or(search_domain, 'effective_ns_max', NaN));
    pass_fail = ~isempty(sub) && min(sub.Ns) <= initial_ns_min + 1.0e-9;
    rows(idx, :) = { ...
        string(figure_name), ...
        double(group_row.h_km(1)), ...
        "h_km=" + string(group_row.h_km(1)) + ";family_name=" + string(group_row.family_name(1)) + ";i_deg=" + string(group_row.i_deg(1)), ...
        double(initial_ns_min), ...
        double(final_ns_max), ...
        double(sum(~padded_mask)), ...
        double(sum(padded_mask)), ...
        string(history_fill_mode), ...
        string(history_origin_mode), ...
        logical(any(padded_mask)), ...
        logical(any(padded_mask)), ...
        logical(pass_fail)};
    end
    summary_table = cell2table(rows, 'VariableNames', {'figure_name', 'height_km', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'history_origin_mode', 'history_padding_applied', 'padding_applied', 'pass_fail'});
end

function view_meta = local_build_comparison_view_meta(search_domain, raw_gap_table, view_table, legacy_meta, closed_meta)
view_meta = struct();
view_meta.domain_view = string(local_getfield_or(legacy_meta, 'domain_view', local_getfield_or(closed_meta, 'domain_view', "")));
view_meta.history_padding_applied = logical(local_getfield_or(legacy_meta, 'history_padding_applied', false) || local_getfield_or(closed_meta, 'history_padding_applied', false));
view_meta.history_fill_mode = string(local_getfield_or(legacy_meta, 'history_fill_mode', local_getfield_or(closed_meta, 'history_fill_mode', "")));
view_meta.history_origin = string(local_getfield_or(legacy_meta, 'history_origin', local_getfield_or(closed_meta, 'history_origin', "")));
view_meta.initial_ns_min = double(local_getfield_or(search_domain, 'history_ns_min', NaN));
view_meta.effective_ns_min = double(local_getfield_or(search_domain, 'effective_ns_min', NaN));
view_meta.final_ns_max = double(local_getfield_or(search_domain, 'history_ns_max', local_getfield_or(search_domain, 'effective_ns_max', NaN)));
view_meta.source_table_min_ns = local_min_table_value(raw_gap_table, 'Ns');
view_meta.source_table_max_ns = local_max_table_value(raw_gap_table, 'Ns');
view_meta.source_table_row_count = height(raw_gap_table);
view_meta.view_table_min_ns = local_min_table_value(view_table, 'Ns');
view_meta.view_table_max_ns = local_max_table_value(view_table, 'Ns');
view_meta.pass_fail = ~isempty(view_table);
view_meta.root_cause_tag = "correct";
end

function data = local_fill_missing_numeric(data, fill_value)
mask = isnan(data);
data(mask) = fill_value;
end

function data = local_fill_missing_logical(data, fill_value)
mask = false(size(data));
if isnumeric(data)
    mask = isnan(data);
    data = logical(data);
end
if islogical(data)
    % no-op
elseif isstring(data)
    mask = ismissing(data);
    data = data == "true";
elseif iscell(data)
    mask = cellfun(@isempty, data);
    data = logical(cellfun(@(x) ~isempty(x) && logical(x), data));
end
data(mask) = logical(fill_value);
end

function value = local_pick_first_nonempty_string(T, candidate_fields, fallback)
value = string(fallback);
for idx = 1:numel(candidate_fields)
    field_name = candidate_fields{idx};
    if ~ismember(field_name, T.Properties.VariableNames)
        continue;
    end
    column = string(T.(field_name));
    column = column(column ~= "");
    if ~isempty(column)
        value = string(column(1));
        return;
    end
end
end

function value = local_min_table_value(T, field_name)
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

function value = local_max_table_value(T, field_name)
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
