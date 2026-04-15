function out = activate_ch5r_runtime_override(case_id, opts)
%ACTIVATE_CH5R_RUNTIME_OVERRIDE
% Activate runtime override for Chapter 5 multicase execution.
%
% Fields written:
%   rt.enabled = true
%   rt.case_id
%   rt.use_constellation_lock
%   rt.lock_name

if nargin < 2 || isempty(opts)
    opts = struct();
end

if nargin < 1 || isempty(case_id)
    error('activate_ch5r_runtime_override:InvalidInput', 'case_id is required.');
end

if ~isfield(opts, 'use_constellation_lock') || isempty(opts.use_constellation_lock)
    opts.use_constellation_lock = true;
end
if ~isfield(opts, 'lock_name') || isempty(opts.lock_name)
    opts.lock_name = 'ch5_constellation_lock';
end

project_root = pwd;
override_dir = fullfile(project_root, 'outputs', 'ch5_rebuild', 'runtime_override');
if ~exist(override_dir, 'dir')
    mkdir(override_dir);
end

mat_file = fullfile(override_dir, 'ch5_runtime_override.mat');
json_file = fullfile(override_dir, 'ch5_runtime_override.json');

rt = struct();
rt.enabled = true;
rt.case_id = char(string(case_id));
rt.use_constellation_lock = logical(opts.use_constellation_lock);
rt.lock_name = char(string(opts.lock_name));
rt.saved_at = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
rt.project_root = project_root;

save(mat_file, 'rt');

json_text = jsonencode(rt, PrettyPrint=true);
fid = fopen(json_file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', json_text);

disp(' ')
disp('=== [ch5r:runtime-override] activated ===')
disp(rt)

out = struct();
out.ok = true;
out.paths = struct('mat_file', mat_file, 'json_file', json_file, 'output_dir', override_dir);
out.rt = rt;
end
