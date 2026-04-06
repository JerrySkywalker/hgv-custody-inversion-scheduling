function out = test_ch5b_plot_trajectory_3d()
%TEST_CH5B_PLOT_TRAJECTORY_3D
% Smoke test for Chapter 5 trajectory 3D plotting.
%
% Purpose:
%   - resolve representative trajectories
%   - generate individual 3D plots
%   - generate family 3D overlay plot
%   - save figures for manual inspection and CI smoke usage

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

sample_ids = {'N01', 'N02', 'C1_track_plane_aligned'};

out_dir = fullfile(cfg.path.output_root, 'tests', 'test_ch5b_plot_trajectory_3d');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

traj_samples = cell(1, numel(sample_ids));
png_files = cell(1, numel(sample_ids));

for i = 1:numel(sample_ids)
    traj_samples{i} = resolve_trajectory_sample(registry, sample_ids{i}, cfg);

    fig_i = plot_ch5b_trajectory_3d(traj_samples{i}, struct( ...
        'visible', 'off', ...
        'coord_frame', 'enu', ...
        'title_prefix', 'test_ch5b_plot_trajectory_3d'));

    png_i = fullfile(out_dir, sprintf('single_%s_3d_enu.png', sample_ids{i}));
    fig_i_path = fullfile(out_dir, sprintf('single_%s_3d_enu.fig', sample_ids{i}));

    saveas(fig_i, png_i);
    savefig(fig_i, fig_i_path);

    png_files{i} = png_i;
end

fig_family = plot_ch5b_trajectory_family_3d(traj_samples, struct( ...
    'visible', 'off', ...
    'coord_frame', 'enu', ...
    'title_text', 'test_ch5b_plot_trajectory_3d family overlay'));

family_png = fullfile(out_dir, 'family_overlay_3d_enu.png');
family_fig = fullfile(out_dir, 'family_overlay_3d_enu.fig');

saveas(fig_family, family_png);
savefig(fig_family, family_fig);

out = struct();
out.ok = true;
out.test_name = 'test_ch5b_plot_trajectory_3d';
out.sample_ids = sample_ids;
out.single_png_files = png_files;
out.family_png = family_png;
out.family_fig = family_fig;
out.output_dir = out_dir;
out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

disp('=== test_ch5b_plot_trajectory_3d ===');
disp(out);

save(fullfile(out_dir, 'test_ch5b_plot_trajectory_3d_out.mat'), 'out');

end
