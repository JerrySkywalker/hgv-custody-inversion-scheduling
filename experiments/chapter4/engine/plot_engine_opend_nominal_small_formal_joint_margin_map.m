function result = plot_engine_opend_nominal_small_formal_joint_margin_map()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table(:, {'P', 'T', 'joint_margin'});
tbl = renamevars(tbl, 'joint_margin', 'value');

opts = struct();
opts.title_text = 'Engine OpenD Joint Margin Map (Nominal Small-Formal)';
opts.x_label = 'T';
opts.y_label = 'P';
opts.show_text = true;
opts.text_format = '%.2g';
opts.colorbar_label = 'Joint Margin';

[fig, ax, grid_data] = plot_heatmap_from_table(tbl, 'value', opts);
paths = export_figure_bundle(fig, ...
    fullfile('outputs', 'experiments', 'chapter4', 'engine', 'figures'), ...
    'engine_opend_nominal_small_formal_joint_margin_map', r.manifest_paths.txt_path);

result = struct();
result.figure = fig;
result.axes = ax;
result.grid_data = grid_data;
result.paths = paths;
end
