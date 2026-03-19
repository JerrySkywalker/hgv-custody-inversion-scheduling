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
    summary_context_csv = fullfile(paths.tables, sprintf('MB_comparison_summary_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(pair.requirement_gap_table, gap_csv);
    milestone_common_save_table(pair.passratio_gap_table, pass_csv);
    milestone_common_save_table(pair.frontier_gap_table, frontier_csv);
    milestone_common_save_table(struct2table(pair.summary), summary_context_csv);

    fig_gap = plot_semantic_gap_heatmap(pair.requirement_gap_table, pair.h_km, sensor_label);
    gap_png = fullfile(paths.figures, sprintf('MB_comparison_gap_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_gap, gap_png);
    close(fig_gap);

    fig_pass = plot_semantic_gap_passratio_curves(pair.passratio_gap_table, pair.h_km, sensor_label);
    pass_png = fullfile(paths.figures, sprintf('MB_comparison_passratio_overlay_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);

    fig_frontier = plot_semantic_gap_frontier_shift(pair.frontier_gap_table, pair.h_km, sensor_label);
    frontier_png = fullfile(paths.figures, sprintf('MB_comparison_frontier_shift_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_frontier, frontier_png);
    close(fig_frontier);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('summary_%s', h_label))) = string(summary_context_csv);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('gap_heatmap_iP_%s', h_label))) = string(gap_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_overlay_%s', h_label))) = string(pass_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('frontier_shift_%s', h_label))) = string(frontier_png);
end
end
