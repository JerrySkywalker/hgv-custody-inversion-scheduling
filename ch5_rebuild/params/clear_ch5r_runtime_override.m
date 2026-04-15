function out = clear_ch5r_runtime_override()
%CLEAR_CH5R_RUNTIME_OVERRIDE
% Clear runtime override files.

project_root = pwd;
override_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'runtime_override');
mat_file = fullfile(override_dir, 'ch5_runtime_override.mat');
json_file = fullfile(override_dir, 'ch5_runtime_override.json');

if isfile(mat_file)
    delete(mat_file);
end
if isfile(json_file)
    delete(json_file);
end

disp(' ')
disp('=== [ch5r:runtime-override] cleared ===')
disp(override_dir)

out = struct();
out.ok = true;
out.paths = struct('mat_file', mat_file, 'json_file', json_file, 'output_dir', override_dir);
end
