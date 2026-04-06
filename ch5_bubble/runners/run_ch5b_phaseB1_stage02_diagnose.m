function out = run_ch5b_phaseB1_stage02_diagnose()
%RUN_CH5B_PHASEB1_STAGE02_DIAGNOSE Diagnose Stage02 trajectory artifacts.

cfg = default_ch5b_params();

phase_name = 'phaseB1_stage02_diagnose';
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

stage02_info = load_stage02_trajectory_family(cfg);

out = struct();
out.ok = true;
out.phase = 'B1.2';
out.framework = cfg.framework.name;
out.scan_mode = stage02_info.scan_mode;
out.total_candidate_mat_files = stage02_info.total_candidate_mat_files;
out.record_count = stage02_info.record_count;
out.output_phase_dir = phase_dir;
out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

disp('=== ch5_bubble Phase B1.2 stage02 diagnose ===');
disp(out);

save(fullfile(mats_dir, 'phaseB1_stage02_diagnose_out.mat'), 'out', 'cfg', 'stage02_info');

fid = fopen(fullfile(logs_dir, 'phaseB1_stage02_diagnose_summary.txt'), 'w');
fprintf(fid, 'framework=%s\n', out.framework);
fprintf(fid, 'phase=%s\n', out.phase);
fprintf(fid, 'scan_mode=%s\n', out.scan_mode);
fprintf(fid, 'total_candidate_mat_files=%d\n', out.total_candidate_mat_files);
fprintf(fid, 'record_count=%d\n', out.record_count);
fprintf(fid, 'output_phase_dir=%s\n', out.output_phase_dir);
fprintf(fid, 'timestamp=%s\n', out.timestamp);
fclose(fid);

if ~isempty(stage02_info.records)
    T = struct2table(stage02_info.records);
    writetable(T, fullfile(tables_dir, 'stage02_candidate_records.csv'));
end

end
