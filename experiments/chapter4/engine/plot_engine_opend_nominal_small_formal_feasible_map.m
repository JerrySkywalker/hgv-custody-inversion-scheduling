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

[fig, ax, grid_data] = plot_pt_grid_core(tbl, 'P', 'T', 'value', opts);
paths = local_save_plot(fig, 'engine_opend_nominal_small_formal_feasible_map', r.manifest_paths.txt_path);

result = struct();
result.figure = fig;
result.axes = ax;
result.grid_data = grid_data;
result.paths = paths;
end

function paths = local_save_plot(fig, stem, source_manifest)
output_dir = fullfile('outputs', 'experiments', 'chapter4', 'engine', 'figures');
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
png_path = fullfile(output_dir, sprintf('%s_%s.png', stem, timestamp));
fig_path = fullfile(output_dir, sprintf('%s_%s.fig', stem, timestamp));
latest_png = fullfile(output_dir, sprintf('%s_latest.png', stem));
latest_fig = fullfile(output_dir, sprintf('%s_latest.fig', stem));
manifest_txt = fullfile(output_dir, sprintf('%s_manifest_latest.txt', stem));

saveas(fig, png_path);
savefig(fig, fig_path);
saveas(fig, latest_png);
savefig(fig, latest_fig);

fid = fopen(manifest_txt, 'w');
fprintf(fid, 'plot_name: %s\n', stem);
fprintf(fid, 'created_at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'png_path: %s\n', png_path);
fprintf(fid, 'fig_path: %s\n', fig_path);
fprintf(fid, 'latest_png: %s\n', latest_png);
fprintf(fid, 'latest_fig: %s\n', latest_fig);
fprintf(fid, 'source_manifest: %s\n', source_manifest);
fclose(fid);

paths = struct('png_path', png_path, 'fig_path', fig_path, ...
    'latest_png', latest_png, 'latest_fig', latest_fig, 'manifest_txt', manifest_txt);
end
