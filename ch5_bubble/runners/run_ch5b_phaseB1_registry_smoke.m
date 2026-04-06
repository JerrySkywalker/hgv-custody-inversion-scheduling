function out = run_ch5b_phaseB1_registry_smoke(sample_id)
%RUN_CH5B_PHASEB1_REGISTRY_SMOKE Smoke runner for trajectory registry layer.

if nargin < 1
    sample_id = 'N01';
end

cfg = default_ch5b_params();

phase_name = 'phaseB1_registry';
phase_dir = fullfile(cfg.path.output_root, phase_name);
logs_dir = fullfile(phase_dir, 'logs');
tables_dir = fullfile(phase_dir, 'tables');
mats_dir = fullfile(phase_dir, 'mats');

dirs_to_create = {cfg.path.output_root, phase_dir, logs_dir, tables_dir, mats_dir};
for i = 1:numel(dirs_to_create)
    if ~exist(dirs_to_create{i}, 'dir')
        mkdir(dirs_to_create{i});
    end
end

registry = build_trajectory_registry(cfg);
traj_sample = resolve_trajectory_sample(registry, sample_id, cfg);
summary = summarize_trajectory_sample(traj_sample);
diag_out = diagnose_trajectory_timeline(traj_sample);

out = struct();
out.ok = true;
out.phase = 'B1';
out.framework = cfg.framework.name;
out.registry_version = registry.version;
out.sample_count = registry.sample_count;
out.sample_id = summary.sample_id;
out.family_id = summary.family_id;
out.n_steps = summary.n_steps;
out.dt = summary.dt;
out.t_start = summary.t_start;
out.t_end = summary.t_end;
out.terminal_reason = summary.terminal_reason;
out.time_monotonic = diag_out.time_monotonic;
out.truth_rows_match = diag_out.truth_rows_match;
out.is_uniform_dt = diag_out.is_uniform_dt;
out.output_phase_dir = phase_dir;
out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

disp('=== ch5_bubble Phase B1 registry smoke ===');
disp(out);

save(fullfile(mats_dir, 'phaseB1_registry_smoke_out.mat'), ...
    'out', 'cfg', 'registry', 'traj_sample', 'summary', 'diag_out');

fid = fopen(fullfile(logs_dir, 'phaseB1_registry_summary.txt'), 'w');
fprintf(fid, 'framework=%s\n', out.framework);
fprintf(fid, 'phase=%s\n', out.phase);
fprintf(fid, 'registry_version=%s\n', out.registry_version);
fprintf(fid, 'sample_count=%d\n', out.sample_count);
fprintf(fid, 'sample_id=%s\n', out.sample_id);
fprintf(fid, 'family_id=%s\n', out.family_id);
fprintf(fid, 'n_steps=%d\n', out.n_steps);
fprintf(fid, 'dt=%.6f\n', out.dt);
fprintf(fid, 't_start=%.6f\n', out.t_start);
fprintf(fid, 't_end=%.6f\n', out.t_end);
fprintf(fid, 'terminal_reason=%s\n', out.terminal_reason);
fprintf(fid, 'time_monotonic=%d\n', out.time_monotonic);
fprintf(fid, 'truth_rows_match=%d\n', out.truth_rows_match);
fprintf(fid, 'is_uniform_dt=%d\n', out.is_uniform_dt);
fprintf(fid, 'output_phase_dir=%s\n', out.output_phase_dir);
fprintf(fid, 'timestamp=%s\n', out.timestamp);
fclose(fid);

end
