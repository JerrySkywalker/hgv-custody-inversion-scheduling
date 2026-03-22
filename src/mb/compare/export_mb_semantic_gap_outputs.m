function artifacts = export_mb_semantic_gap_outputs(legacy_output, closed_output, paths, plot_options)
%EXPORT_MB_SEMANTIC_GAP_OUTPUTS Export comparison artifacts between legacyDG and closedD.

if nargin < 4 || isempty(plot_options)
    plot_options = struct();
end

comparison = build_semantic_gap_tables(legacy_output, closed_output);
sensor_group = char(string(comparison.sensor_group));
sensor_label = char(string(comparison.sensor_label));

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
    frontier_csv = fullfile(paths.tables, sprintf('MB_comparison_frontier_shift_%s_%s.csv', h_label, sensor_group));
    frontier_diag_csv = fullfile(paths.tables, sprintf('MB_comparison_frontier_diagnostic_%s_%s.csv', h_label, sensor_group));
    summary_context_csv = fullfile(paths.tables, sprintf('MB_comparison_summary_%s_%s.csv', h_label, sensor_group));
    export_grade_csv = fullfile(paths.tables, sprintf('MB_comparison_export_grade_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(pair.requirement_gap_table, gap_csv);
    milestone_common_save_table(pair.passratio_gap_table, pass_csv);
    milestone_common_save_table(pair.frontier_gap_table, frontier_csv);
    milestone_common_save_table(pair.frontier_diagnostic_table, frontier_diag_csv);
    milestone_common_save_table(local_summary_context_table(pair), summary_context_csv);

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

    fig_pass = plot_semantic_gap_passratio_curves(pair.passratio_gap_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "expanded_final_shared", ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pass_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);

    fig_frontier = plot_semantic_gap_frontier_shift(pair.frontier_gap_table, pair.h_km, sensor_label, struct( ...
        'frontier_truncation_table', pair.frontier_truncation_table, ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    frontier_png = fullfile(paths.figures, sprintf('MB_comparison_frontier_shift_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_frontier, frontier_png);
    close(fig_frontier);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_diagnostic_%s', h_label))) = string(frontier_diag_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('summary_%s', h_label))) = string(summary_context_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('export_grade_%s', h_label))) = string(export_grade_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('boundary_hit_%s', h_label))) = diag_artifacts.boundary_hit_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_saturation_%s', h_label))) = diag_artifacts.passratio_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_truncation_%s', h_label))) = diag_artifacts.frontier_csv;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_png);
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
    local_maybe_export_paper_ready(@() plot_semantic_gap_passratio_curves(pair.passratio_gap_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table, ...
        'search_domain_bounds', [pair.search_domain.ns_search_min, pair.search_domain.ns_search_max], ...
        'plot_domain_label', "expanded_final_shared", ...
        'runtime', local_getfield_or(plot_options, 'runtime', struct()), ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_%s_%s_paperReady.png', h_label, sensor_group)), ...
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

function summary_table = local_summary_context_table(pair)
summary_table = struct2table(pair.summary);
summary_table = addvars(summary_table, ...
    repmat(pair.h_km, height(summary_table), 1), ...
    repmat(string(pair.family_name), height(summary_table), 1), ...
    'Before', 1, ...
    'NewVariableNames', {'h_km', 'family_name'});
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
