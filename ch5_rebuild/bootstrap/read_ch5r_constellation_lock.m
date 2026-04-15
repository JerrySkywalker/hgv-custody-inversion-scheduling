function out = read_ch5r_constellation_lock(opts)
%READ_CH5R_CONSTELLATION_LOCK
% Read Chapter 5 constellation lock from .mat file.

if nargin < 1 || isempty(opts)
    opts = struct();
end

project_root = pwd;
out_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phaseR0_bootstrap', 'lock');

if ~isfield(opts, 'lock_name') || isempty(opts.lock_name)
    lock_name = 'ch5_constellation_lock';
else
    lock_name = char(opts.lock_name);
end

mat_file = fullfile(out_dir, [lock_name '.mat']);
json_file = fullfile(out_dir, [lock_name '.json']);

if ~isfile(mat_file)
    error('[ch5r:lock] MAT lock file not found: %s', mat_file);
end

S = load(mat_file);
if ~isfield(S, 'lock_data')
    error('[ch5r:lock] lock_data missing in MAT lock file.');
end

disp(' ')
disp('=== [ch5r:lock] read summary ===')
disp(['mat file  : ' mat_file])
if isfile(json_file)
    disp(['json file : ' json_file])
end
disp(S.lock_data)

out = struct();
out.ok = true;
out.paths = struct('mat_file', mat_file, 'json_file', json_file, 'output_dir', out_dir);
out.lock = S.lock_data;
end
