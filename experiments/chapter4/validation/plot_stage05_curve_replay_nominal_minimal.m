function result = plot_stage05_curve_replay_nominal_minimal()
startup;

r_replay = run_stage05_curve_replay_nominal_minimal();
tbl = r_replay.replay_result.curve_table;

opts = struct();
opts.title_text = 'Stage05 Replay Curve (Nominal Minimal)';
opts.x_label = 'Ns';
opts.y_label = 'Best Pass Ratio';
opts.marker = 'o';
opts.line_width = 1.5;
opts.show_grid = true;
opts.show_text = true;
opts.text_format = '%.2g';

[fig, ax] = plot_envelope_curve_from_table(tbl, 'Ns', 'best_pass', opts);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation', 'figures');
bundle = export_figure_bundle(fig, output_dir, ...
    'stage05_curve_replay_nominal_minimal', r_replay.manifest_paths.txt_path);

result = struct();
result.replay_result = r_replay.replay_result;
result.figure = fig;
result.axes = ax;
result.png_path = bundle.png_path;
result.fig_path = bundle.fig_path;
result.latest_png = bundle.latest_png;
result.latest_fig = bundle.latest_fig;
result.manifest_txt = bundle.manifest_txt;

disp('[plot] Stage05 nominal minimal replay curve completed.');
disp(result);
end
