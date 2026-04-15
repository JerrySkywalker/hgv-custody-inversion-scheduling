function out = write_ch5r_constellation_lock(lock_data, opts)
%WRITE_CH5R_CONSTELLATION_LOCK
% Write Chapter 5 constellation lock files (.mat + .json)

if nargin < 2 || isempty(opts)
    opts = struct();
end

if nargin < 1 || isempty(lock_data) || ~isstruct(lock_data)
    error('lock_data must be a non-empty struct.');
end

project_root = pwd;
out_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phaseR0_bootstrap', 'lock');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

if ~isfield(opts, 'lock_name') || isempty(opts.lock_name)
    lock_name = 'ch5_constellation_lock';
else
    lock_name = char(opts.lock_name);
end

mat_file = fullfile(out_dir, [lock_name '.mat']);
json_file = fullfile(out_dir, [lock_name '.json']);

lock_data.saved_at = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
lock_data.project_root = project_root;

save(mat_file, 'lock_data');

json_text = jsonencode(lock_data, PrettyPrint=true);
fid = fopen(json_file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', json_text);

disp(' ')
disp('=== [ch5r:lock] write summary ===')
disp(['mat file  : ' mat_file])
disp(['json file : ' json_file])

out = struct();
out.ok = true;
out.paths = struct('mat_file', mat_file, 'json_file', json_file, 'output_dir', out_dir);
out.lock = lock_data;
end
