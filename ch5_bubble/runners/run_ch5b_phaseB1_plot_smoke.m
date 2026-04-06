function out = run_ch5b_phaseB1_plot_smoke()
%RUN_CH5B_PHASEB1_PLOT_SMOKE Smoke runner for trajectory 3D plotting.

cfg = default_ch5b_params();

phase_name = 'phaseB1_plot_smoke';
phase_dir = fullfile(cfg.path.output_root, phase_name);
logs_dir = fullfile(phase_dir, 'logs');
figs_dir = fullfile(phase_dir, 'figs');
mats_dir = fullfile(phase_dir, 'mats');

dirs_to_create = {cfg.path.output_root, phase_dir, logs_dir, figs_dir, mats_dir};
for i = 1:numel(dirs_to_create)
    if ~exist(dirs_to_create{i}, 'dir')
        mkdir(dirs_to_create{i});
    end
end

registry = build_trajectory_registry(cfg);

traj_N01 = resolve_trajectory_sample(registry, 'N01', cfg);
traj_N02 = resolve_trajectory_sample(registry, 'N02', cfg);
traj_C01 = resolve_trajectory_sample(registry, 'C01', cfg);

traj_samples = [traj_N01, traj_N02, traj_C01];

plot_opts = struct();
plot_opts.visible = 'off';
plot_opts.show_start_end = true;
plot_opts.title_text = 'Phase B1 trajectory family 3D';

export_out = export_ch5b_trajectory_family_3d( ...
    traj_samples, figs_dir, 'phaseB1_trajectory_family_3d', plot_opts);

out = struct();
out.ok = true;
out.phase = 'B1_plot';
out.framework = cfg.framework.name;
out.sample_ids = {traj_samples.sample_id};
out.family_ids = {traj_samples.family_id};
out.png_path = export_out.png_path;
out.fig_path = export_out.fig_path;
out.output_phase_dir = phase_dir;
out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

disp('=== ch5_bubble Phase B1 plot smoke ===');
disp(out);

save(fullfile(mats_dir, 'phaseB1_plot_smoke_out.mat'), ...
    'out', 'cfg', 'registry', 'traj_samples', 'plot_opts', 'export_out');

fid = fopen(fullfile(logs_dir, 'phaseB1_plot_smoke_summary.txt'), 'w');
fprintf(fid, 'framework=%s\n', out.framework);
fprintf(fid, 'phase=%s\n', out.phase);
fprintf(fid, 'sample_ids=%s\n', strjoin(out.sample_ids, ','));
fprintf(fid, 'family_ids=%s\n', strjoin(out.family_ids, ','));
fprintf(fid, 'png_path=%s\n', out.png_path);
fprintf(fid, 'fig_path=%s\n', out.fig_path);
fprintf(fid, 'output_phase_dir=%s\n', out.output_phase_dir);
fprintf(fid, 'timestamp=%s\n', out.timestamp);
fclose(fid);

end
