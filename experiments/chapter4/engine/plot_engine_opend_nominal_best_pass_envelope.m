function result = plot_engine_opend_nominal_best_pass_envelope()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.envelope_result.envelope_table(:, {'Ns', 'best_pass'});

opts = struct();
opts.title_text = 'Engine OpenD Best-Pass Envelope (Nominal)';
opts.x_label = 'Ns';
opts.y_label = 'Best Pass Ratio';
opts.marker = 'o';
opts.line_width = 1.5;
opts.show_grid = true;
opts.show_text = true;
opts.text_format = '%.2g';

[fig, ax] = plot_envelope_curve_from_table(tbl, 'Ns', 'best_pass', opts);
paths = export_figure_bundle(fig, ...
    fullfile('outputs', 'experiments', 'chapter4', 'engine', 'figures'), ...
    'engine_opend_nominal_best_pass_envelope', r.manifest_paths.txt_path);

result = struct();
result.figure = fig;
result.axes = ax;
result.envelope_table = tbl;
result.paths = paths;
end
