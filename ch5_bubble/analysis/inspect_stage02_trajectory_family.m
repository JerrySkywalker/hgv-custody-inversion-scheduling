function inspect_stage02_trajectory_family()
%INSPECT_STAGE02_TRAJECTORY_FAMILY Diagnose possible Stage02 trajectory MAT files.

cfg = default_ch5b_params();
stage02_info = load_stage02_trajectory_family(cfg);

disp('=== inspect_stage02_trajectory_family :: summary ===');
disp(rmfield(stage02_info, 'records'));

if ~isempty(stage02_info.records)
    disp('=== inspect_stage02_trajectory_family :: records ===');
    disp(stage02_info.records);
else
    disp('No Stage02-related MAT files were detected by current diagnose rules.');
end

end
