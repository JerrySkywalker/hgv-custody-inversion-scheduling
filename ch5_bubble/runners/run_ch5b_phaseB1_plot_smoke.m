function out = run_ch5b_phaseB1_plot_smoke(sample_ids, coord_frame)
%RUN_CH5B_PHASEB1_PLOT_SMOKE Smoke runner for real trajectory 3D plotting.

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

if nargin < 1 || isempty(sample_ids)
    preferred = {'N01', 'H01_+000', 'C1_track_plane_aligned'};
    sample_ids = local_pick_existing_ids(preferred, registry.sample_ids);
    if isempty(sample_ids)
        sample_ids = registry.sample_ids(1:min(3, numel(registry.sample_ids)));
    end
end

if nargin < 2 || isempty(coord_frame)
    coord_frame = 'enu';
end

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

traj_samples = repmat(struct(), 1, numel(sample_ids));
for i = 1:numel(sample_ids)
    traj_samples(i) = resolve_trajectory_sample(registry, sample_ids{i}, cfg);
end

plot_opts = struct();
plot_opts.visible = 'off';
plot_opts.show_start_end = true;
plot_opts.coord_frame = coord_frame;
plot_opts.title_text = 'Phase B1 real trajectory family 3D';

export_out = export_ch5b_trajectory_family_3d( ...
    traj_samples, figs_dir, sprintf('phaseB1_trajectory_family_3d_%s', lower(coord_frame)), plot_opts);

out = struct();
out.ok = true;
out.phase = 'B1_plot';
out.framework = cfg.framework.name;
out.sample_ids = {traj_samples.sample_id};
out.family_ids = {traj_samples.family_id};
out.coord_frame = coord_frame;
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
fprintf(fid, 'coord_frame=%s\n', out.coord_frame);
fprintf(fid, 'png_path=%s\n', out.png_path);
fprintf(fid, 'fig_path=%s\n', out.fig_path);
fprintf(fid, 'output_phase_dir=%s\n', out.output_phase_dir);
fprintf(fid, 'timestamp=%s\n', out.timestamp);
fclose(fid);

end

function picked = local_pick_existing_ids(preferred, available)
picked = {};
for i = 1:numel(preferred)
    if any(strcmp(available, preferred{i}))
        picked{end+1} = preferred{i}; %#ok<AGROW>
    end
end
end
