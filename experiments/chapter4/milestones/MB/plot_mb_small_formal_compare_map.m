function result = plot_mb_small_formal_compare_map()
startup;

r_cmp = run_MB_small_formal_compare_master();
tbl = r_cmp.compare_result.compare_table;

plot_tbl = tbl(:, {'P','T','joint_margin_diff'});
plot_tbl = renamevars(plot_tbl, {'joint_margin_diff'}, {'value'});

opts = struct();
opts.title_text = 'MB Small-Formal Compare Map (Nominal - Heading)';
opts.x_label = 'T';
opts.y_label = 'P';
opts.show_text = true;
opts.text_format = '%.2g';
opts.colorbar_label = 'Joint Margin Difference';

[fig, ax, grid_data] = plot_pt_grid_core(plot_tbl, 'P', 'T', 'value', opts);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB', 'figures');
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
png_path = fullfile(output_dir, sprintf('mb_small_formal_compare_map_%s.png', timestamp));
fig_path = fullfile(output_dir, sprintf('mb_small_formal_compare_map_%s.fig', timestamp));
latest_png = fullfile(output_dir, 'mb_small_formal_compare_map_latest.png');
latest_fig = fullfile(output_dir, 'mb_small_formal_compare_map_latest.fig');
manifest_txt = fullfile(output_dir, 'mb_small_formal_compare_map_manifest_latest.txt');

saveas(fig, png_path);
savefig(fig, fig_path);
saveas(fig, latest_png);
savefig(fig, latest_fig);

fid = fopen(manifest_txt, 'w');
fprintf(fid, 'plot_name: mb_small_formal_compare_map\n');
fprintf(fid, 'created_at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'png_path: %s\n', png_path);
fprintf(fid, 'fig_path: %s\n', fig_path);
fprintf(fid, 'latest_png: %s\n', latest_png);
fprintf(fid, 'latest_fig: %s\n', latest_fig);
fprintf(fid, 'source_manifest: %s\n', r_cmp.manifest_paths.txt_path);
fclose(fid);

result = struct();
result.compare_result = r_cmp.compare_result;
result.figure = fig;
result.axes = ax;
result.grid_data = grid_data;
result.png_path = png_path;
result.fig_path = fig_path;
result.latest_png = latest_png;
result.latest_fig = latest_fig;
result.manifest_txt = manifest_txt;

disp('[plot] MB small-formal compare map completed.');
disp(result);
end
