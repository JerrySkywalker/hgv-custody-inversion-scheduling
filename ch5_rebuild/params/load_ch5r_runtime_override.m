function rt = load_ch5r_runtime_override()
%LOAD_CH5R_RUNTIME_OVERRIDE
% Load runtime override file for Chapter 5 multi-case suite.
%
% Returns [] if no override is active.

project_root = pwd;
override_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'runtime_override');
mat_file = fullfile(override_dir, 'ch5_runtime_override.mat');

if ~isfile(mat_file)
    rt = [];
    return;
end

S = load(mat_file);
if isfield(S, 'rt')
    rt = S.rt;
else
    rt = [];
end
end
