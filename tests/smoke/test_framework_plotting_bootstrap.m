function test_framework_plotting_bootstrap()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;

heat_tbl = tbl(:, {'P','T','joint_margin'});
heat_tbl = renamevars(heat_tbl, 'joint_margin', 'value');
[fig_heat, ~] = plot_heatmap_from_table(heat_tbl, 'value', struct( ...
    'title_text', 'Framework Heatmap Bootstrap', ...
    'colorbar_label', 'Joint Margin'));
bundle_heat = export_figure_bundle(fig_heat, ...
    fullfile('outputs', 'framework', 'plots'), ...
    'framework_heatmap_bootstrap', '');

env_tbl = r.envelope_result.envelope_table(:, {'Ns', 'best_pass'});
[fig_curve, ~] = plot_envelope_curve_from_table(env_tbl, 'Ns', 'best_pass', struct( ...
    'title_text', 'Framework Curve Bootstrap', ...
    'show_text', true));
bundle_curve = export_figure_bundle(fig_curve, ...
    fullfile('outputs', 'framework', 'plots'), ...
    'framework_curve_bootstrap', '');

scatter_tbl = r.scatter_result.scatter_table;
[fig_scatter, ~] = plot_design_scatter_from_table(scatter_tbl, 'x_value', 'y_value', struct( ...
    'title_text', 'Framework Scatter Bootstrap', ...
    'label_col', 'point_label'));
bundle_scatter = export_figure_bundle(fig_scatter, ...
    fullfile('outputs', 'framework', 'plots'), ...
    'framework_scatter_bootstrap', '');

assert(isfile(bundle_heat.png_path) && isfile(bundle_heat.fig_path), 'Heatmap export missing.');
assert(isfile(bundle_curve.png_path) && isfile(bundle_curve.fig_path), 'Curve export missing.');
assert(isfile(bundle_scatter.png_path) && isfile(bundle_scatter.fig_path), 'Scatter export missing.');

close(fig_heat);
close(fig_curve);
close(fig_scatter);

disp('test_framework_plotting_bootstrap passed.');
end
