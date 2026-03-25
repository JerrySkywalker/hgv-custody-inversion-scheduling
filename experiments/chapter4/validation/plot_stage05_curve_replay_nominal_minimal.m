function result = plot_stage05_curve_replay_nominal_minimal()
startup;

r_replay = run_stage05_curve_replay_nominal_minimal();
tbl = r_replay.replay_result.curve_table;

opts = struct();
opts.title_text = 'Stage05 Replay Curve (Nominal Minimal)';
opts.x_label = 'Ns';
opts.y_label = 'Feasible Ratio';
opts.marker = 'o';
opts.line_width = 1.5;
opts.show_grid = true;
opts.show_text = true;
opts.text_format = '%.2g';

[fig, ax] = plot_xy_curve_core(tbl, 'Ns', 'feasible_ratio', opts);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation', 'figures');
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
png_path = fullfile(output_dir, sprintf('stage05_curve_replay_nominal_minimal_%s.png', timestamp));
fig_path = fullfile(output_dir, sprintf('stage05_curve_replay_nominal_minimal_%s.fig', timestamp));
latest_png = fullfile(output_dir, 'stage05_curve_replay_nominal_minimal_latest.png');
latest_fig = fullfile(output_dir, 'stage05_curve_replay_nominal_minimal_latest.fig');
manifest_txt = fullfile(output_dir, 'stage05_curve_replay_nominal_minimal_manifest_latest.txt');

saveas(fig, png_path);
savefig(fig, fig_path);
saveas(fig, latest_png);
savefig(fig, latest_fig);

fid = fopen(manifest_txt, 'w');
fprintf(fid, 'plot_name: stage05_curve_replay_nominal_minimal\n');
fprintf(fid, 'created_at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'png_path: %s\n', png_path);
fprintf(fid, 'fig_path: %s\n', fig_path);
fprintf(fid, 'latest_png: %s\n', latest_png);
fprintf(fid, 'latest_fig: %s\n', latest_fig);
fprintf(fid, 'source_manifest: %s\n', r_replay.manifest_paths.txt_path);
fclose(fid);

result = struct();
result.replay_result = r_replay.replay_result;
result.figure = fig;
result.axes = ax;
result.png_path = png_path;
result.fig_path = fig_path;
result.latest_png = latest_png;
result.latest_fig = latest_fig;
result.manifest_txt = manifest_txt;

disp('[plot] Stage05 nominal minimal replay curve completed.');
disp(result);
end
