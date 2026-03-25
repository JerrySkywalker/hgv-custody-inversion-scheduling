function demo_result = run_framework_pipeline_bootstrap_demo()
%RUN_FRAMEWORK_PIPELINE_BOOTSTRAP_DEMO Minimal framework pipeline demo.

startup;

cfg = default_params();
gamma_info = load_stage04_nominal_gamma_req();
cfg.stage04.Tw_s = gamma_info.Tw_s;
cfg.stage04.gamma_req = gamma_info.gamma_req;

grid_profile = make_ch4_design_grid_profile();
rows = grid_profile.validation_stage05.rows;
task_family = build_task_family(struct('family_name', 'nominal', 'max_cases', 1), cfg);

search_result = run_design_grid_search_opend(rows, task_family, cfg, struct( ...
    'gamma_eff_scalar', gamma_info.gamma_req, ...
    'run_tag', 'framework_pipeline_bootstrap_demo', ...
    'source_profile', struct('name', 'framework_pipeline_bootstrap_demo')));

grid_table = search_result.grid_table;
envelope_table = build_best_envelope(grid_table, 'Ns', 'pass_ratio', struct('i_deg', 60), 'max');
curve_table = build_fixed_path_curve(grid_table, struct('mode', 'diag_PT'));
scatter_table = build_design_point_scatter(grid_table, 'Ns', 'pass_ratio', struct(), {'P','T'});
boundary_result = summarize_boundary(grid_table);

derived_payload = struct();
derived_payload.tables = struct( ...
    'envelope_table', envelope_table, ...
    'curve_table', curve_table, ...
    'scatter_table', scatter_table, ...
    'boundary_summary_table', boundary_result.summary_table);
derived_payload.parent_cache_path = search_result.cache_path;
derived_payload.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
derived_payload.run_tag = 'framework_pipeline_bootstrap_demo';
derived_payload.derive_kind = 'demo_bundle';

derived_cache = save_derived_table_cache(derived_payload, struct( ...
    'derive_kind', 'demo_bundle', ...
    'engine_mode', 'opend', ...
    'run_tag', 'framework_pipeline_bootstrap_demo'), struct());

heat_tbl = grid_table(:, {'P','T','joint_margin'});
heat_tbl = renamevars(heat_tbl, 'joint_margin', 'value');
[fig_heat, ~] = plot_heatmap_from_table(heat_tbl, 'value', struct( ...
    'title_text', 'Framework Demo Heatmap', ...
    'colorbar_label', 'Joint Margin'));
[fig_curve, ~] = plot_envelope_curve_from_table(envelope_table, 'Ns', 'pass_ratio', struct( ...
    'title_text', 'Framework Demo Envelope', ...
    'show_text', true));
[fig_scatter, ~] = plot_design_scatter_from_table(scatter_table, 'x_value', 'y_value', struct( ...
    'title_text', 'Framework Demo Scatter', ...
    'label_col', 'point_label'));

plot_dir = fullfile('outputs', 'framework', 'demo', 'figures');
heat_bundle = export_figure_bundle(fig_heat, plot_dir, 'framework_demo_heatmap', search_result.cache_path);
curve_bundle = export_figure_bundle(fig_curve, plot_dir, 'framework_demo_envelope', search_result.cache_path);
scatter_bundle = export_figure_bundle(fig_scatter, plot_dir, 'framework_demo_scatter', search_result.cache_path);

demo_result = struct();
demo_result.search_result = search_result;
demo_result.envelope_table = envelope_table;
demo_result.curve_table = curve_table;
demo_result.scatter_table = scatter_table;
demo_result.boundary_result = boundary_result;
demo_result.derived_cache = derived_cache;
demo_result.heat_bundle = heat_bundle;
demo_result.curve_bundle = curve_bundle;
demo_result.scatter_bundle = scatter_bundle;

close(fig_heat);
close(fig_curve);
close(fig_scatter);
end
