function result = plot_engine_opend_nominal_small_formal_feasible_map()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table(:, {'P', 'T', 'is_feasible'});
tbl = renamevars(tbl, 'is_feasible', 'value');

opts = struct();
opts.title_text = 'Engine OpenD Feasible Map (Nominal Small-Formal)';
opts.x_label = 'T';
opts.y_label = 'P';
opts.show_text = true;
opts.text_format = '%.0f';
opts.colorbar_label = 'Feasible (1/0)';

[fig, ax, grid_data] = plot_heatmap_from_table(tbl, 'value', opts);
paths = export_figure_bundle(fig, ...
    fullfile('outputs', 'experiments', 'chapter4', 'engine', 'figures'), ...
    'engine_opend_nominal_small_formal_feasible_map', r.manifest_paths.txt_path);

result = struct();
result.figure = fig;
result.axes = ax;
result.grid_data = grid_data;
result.paths = paths;
end
