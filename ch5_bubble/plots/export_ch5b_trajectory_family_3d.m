function out = export_ch5b_trajectory_family_3d(traj_samples, out_dir, file_stem, opts)
%EXPORT_CH5B_TRAJECTORY_FAMILY_3D Export trajectory family 3D plot.

if nargin < 4
    opts = struct();
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig = plot_ch5b_trajectory_family_3d(traj_samples, opts);

png_path = fullfile(out_dir, [file_stem, '.png']);
fig_path = fullfile(out_dir, [file_stem, '.fig']);

saveas(fig, png_path);
savefig(fig, fig_path);

out = struct();
out.ok = true;
out.png_path = png_path;
out.fig_path = fig_path;
out.file_stem = file_stem;

end
