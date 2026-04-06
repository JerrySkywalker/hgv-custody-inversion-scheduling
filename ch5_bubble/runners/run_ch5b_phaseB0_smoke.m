function out = run_ch5b_phaseB0_smoke()
%RUN_CH5B_PHASEB0_SMOKE Smoke runner for Phase B0 engineering skeleton.

cfg = default_ch5b_params();

dirs_to_create = { ...
    cfg.path.output_root, ...
    cfg.output.phase_dir, ...
    cfg.output.logs_dir, ...
    cfg.output.tables_dir, ...
    cfg.output.figs_dir, ...
    cfg.output.mats_dir};

for i = 1:numel(dirs_to_create)
    if ~exist(dirs_to_create{i}, 'dir')
        mkdir(dirs_to_create{i});
    end
end

out = struct();
out.ok = true;
out.phase = cfg.framework.phase;
out.framework = cfg.framework.name;
out.version = cfg.framework.version;
out.output_phase_dir = cfg.output.phase_dir;
out.primary_window_mode = cfg.metrics.primary_window_mode;
out.default_policy_name = cfg.policy.default_policy_name;
out.default_sample_id = cfg.trajectory.default_sample_id;
out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

disp('=== ch5_bubble Phase B0 smoke ===');
disp(out);

save(fullfile(cfg.output.mats_dir, 'phaseB0_smoke_out.mat'), 'out', 'cfg');

fid = fopen(fullfile(cfg.output.logs_dir, 'phaseB0_smoke_summary.txt'), 'w');
fprintf(fid, 'framework=%s\n', out.framework);
fprintf(fid, 'version=%s\n', out.version);
fprintf(fid, 'phase=%s\n', out.phase);
fprintf(fid, 'primary_window_mode=%s\n', out.primary_window_mode);
fprintf(fid, 'default_policy_name=%s\n', out.default_policy_name);
fprintf(fid, 'default_sample_id=%s\n', out.default_sample_id);
fprintf(fid, 'output_phase_dir=%s\n', out.output_phase_dir);
fprintf(fid, 'timestamp=%s\n', out.timestamp);
fclose(fid);

end
