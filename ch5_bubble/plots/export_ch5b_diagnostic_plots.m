function out = export_ch5b_diagnostic_plots(traj_samples, out_dir, file_prefix, coord_frame)
%EXPORT_CH5B_DIAGNOSTIC_PLOTS Export 3D / altitude-time / speed-time plots.

if nargin < 4 || isempty(coord_frame)
    coord_frame = 'enu';
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig3d = plot_ch5b_trajectory_family_3d(traj_samples, struct( ...
    'visible', 'off', ...
    'coord_frame', coord_frame, ...
    'title_text', sprintf('%s trajectory family 3D', upper(coord_frame))));

figAlt = plot_ch5b_altitude_time(traj_samples, struct( ...
    'visible', 'off', ...
    'title_text', 'Altitude-Time'));

figSpd = plot_ch5b_speed_time(traj_samples, struct( ...
    'visible', 'off', ...
    'title_text', 'Speed-Time'));

png_3d = fullfile(out_dir, [file_prefix, '_3d_', lower(coord_frame), '.png']);
png_alt = fullfile(out_dir, [file_prefix, '_altitude_time.png']);
png_spd = fullfile(out_dir, [file_prefix, '_speed_time.png']);

fig_3d = fullfile(out_dir, [file_prefix, '_3d_', lower(coord_frame), '.fig']);
fig_alt = fullfile(out_dir, [file_prefix, '_altitude_time.fig']);
fig_spd = fullfile(out_dir, [file_prefix, '_speed_time.fig']);

saveas(fig3d, png_3d);
savefig(fig3d, fig_3d);

saveas(figAlt, png_alt);
savefig(figAlt, fig_alt);

saveas(figSpd, png_spd);
savefig(figSpd, fig_spd);

out = struct();
out.ok = true;
out.png_3d = png_3d;
out.png_altitude = png_alt;
out.png_speed = png_spd;
out.fig_3d = fig_3d;
out.fig_altitude = fig_alt;
out.fig_speed = fig_spd;

end
