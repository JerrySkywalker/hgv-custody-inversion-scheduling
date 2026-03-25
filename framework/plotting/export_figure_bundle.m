function bundle = export_figure_bundle(fig, output_dir, file_stem, source_ref)
%EXPORT_FIGURE_BUNDLE Export PNG/FIG files plus latest copies and a manifest.

if nargin < 4
    source_ref = '';
end

ensure_dir(output_dir);

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
png_path = fullfile(output_dir, sprintf('%s_%s.png', file_stem, timestamp));
fig_path = fullfile(output_dir, sprintf('%s_%s.fig', file_stem, timestamp));
latest_png = fullfile(output_dir, sprintf('%s_latest.png', file_stem));
latest_fig = fullfile(output_dir, sprintf('%s_latest.fig', file_stem));
manifest_txt = fullfile(output_dir, sprintf('%s_manifest_latest.txt', file_stem));

saveas(fig, png_path);
savefig(fig, fig_path);
saveas(fig, latest_png);
savefig(fig, latest_fig);

fid = fopen(manifest_txt, 'w');
if fid < 0
    error('export_figure_bundle:FailedToOpenManifest', ...
        'Failed to open manifest file: %s', manifest_txt);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'file_stem: %s\n', file_stem);
fprintf(fid, 'created_at: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'png_path: %s\n', png_path);
fprintf(fid, 'fig_path: %s\n', fig_path);
fprintf(fid, 'latest_png: %s\n', latest_png);
fprintf(fid, 'latest_fig: %s\n', latest_fig);
fprintf(fid, 'source_ref: %s\n', char(string(source_ref)));

bundle = struct();
bundle.png_path = png_path;
bundle.fig_path = fig_path;
bundle.latest_png = latest_png;
bundle.latest_fig = latest_fig;
bundle.manifest_txt = manifest_txt;
end
