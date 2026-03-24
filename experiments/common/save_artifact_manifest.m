function manifest_paths = save_artifact_manifest(manifest, output_dir, file_prefix)
if nargin < 3
    error('save_artifact_manifest:InvalidInput', ...
        'manifest, output_dir, and file_prefix are required.');
end

if ~isstruct(manifest)
    error('save_artifact_manifest:InvalidManifest', ...
        'manifest must be a struct.');
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');

mat_name = sprintf('%s_manifest_%s.mat', file_prefix, timestamp);
txt_name = sprintf('%s_manifest_latest.txt', file_prefix);

mat_path = fullfile(output_dir, mat_name);
txt_path = fullfile(output_dir, txt_name);

save(mat_path, 'manifest');

fid = fopen(txt_path, 'w');
if fid == -1
    error('save_artifact_manifest:FileOpenFailed', ...
        'Failed to open manifest text file for writing: %s', txt_path);
end

fprintf(fid, 'experiment_name: %s\n', manifest.experiment_name);
fprintf(fid, 'artifact_count: %d\n', manifest.artifact_count);
fprintf(fid, 'created_at: %s\n', manifest.created_at);
fprintf(fid, '\n');

for k = 1:numel(manifest.artifacts)
    a = manifest.artifacts{k};
    fprintf(fid, '[artifact %d]\n', k);
    fprintf(fid, 'file_name: %s\n', a.file_name);
    fprintf(fid, 'file_path: %s\n', a.file_path);
    fprintf(fid, 'latest_file_name: %s\n', a.latest_file_name);
    fprintf(fid, 'latest_file_path: %s\n', a.latest_file_path);
    fprintf(fid, 'row_count: %d\n', a.row_count);
    fprintf(fid, 'col_count: %d\n', a.col_count);
    fprintf(fid, 'timestamp: %s\n', a.timestamp);
    fprintf(fid, '\n');
end

fclose(fid);

manifest_paths = struct();
manifest_paths.mat_path = mat_path;
manifest_paths.txt_path = txt_path;
manifest_paths.meta = struct('status', 'ok');
end
