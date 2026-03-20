function artifacts = export_mb_semantic_gap_outputs(legacy_output, closed_output, paths)
%EXPORT_MB_SEMANTIC_GAP_OUTPUTS Export comparison artifacts between legacyDG and closedD.

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
        'boundary_hit_table', pair.boundary_hit_table));
    gap_png = fullfile(paths.figures, sprintf('MB_comparison_gap_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_gap, gap_png);
    close(fig_gap);

    fig_pass = plot_semantic_gap_passratio_curves(pair.passratio_gap_table, pair.h_km, sensor_label, struct( ...
        'passratio_saturation_table', pair.passratio_saturation_table, ...
        'boundary_hit_table', pair.boundary_hit_table));
    pass_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);

    fig_frontier = plot_semantic_gap_frontier_shift(pair.frontier_gap_table, pair.h_km, sensor_label, struct( ...
        'frontier_truncation_table', pair.frontier_truncation_table));
    frontier_png = fullfile(paths.figures, sprintf('MB_comparison_frontier_shift_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_frontier, frontier_png);
    close(fig_frontier);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_diagnostic_%s', h_label))) = string(frontier_diag_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('summary_%s', h_label))) = string(summary_context_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('boundary_hit_%s', h_label))) = diag_artifacts.boundary_hit_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_saturation_%s', h_label))) = diag_artifacts.passratio_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_truncation_%s', h_label))) = diag_artifacts.frontier_csv;
    artifacts.figures.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_png);
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
