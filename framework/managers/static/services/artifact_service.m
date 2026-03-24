function artifact = artifact_service(table_obj, output_dir, file_prefix, options)
if nargin < 3
    error('artifact_service:InvalidInput', ...
        'table_obj, output_dir, and file_prefix are required.');
end

if nargin < 4 || ~isstruct(options)
    options = struct();
end

if ~istable(table_obj)
    error('artifact_service:InvalidTable', ...
        'table_obj must be a MATLAB table.');
end

write_latest = true;
if isfield(options, 'write_latest') && ~isempty(options.write_latest)
    write_latest = logical(options.write_latest);
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');

file_name = sprintf('%s_%s.csv', file_prefix, timestamp);
file_path = fullfile(output_dir, file_name);
writetable(table_obj, file_path);

latest_file_name = '';
latest_file_path = '';
if write_latest
    latest_file_name = sprintf('%s_latest.csv', file_prefix);
    latest_file_path = fullfile(output_dir, latest_file_name);
    writetable(table_obj, latest_file_path);
end

artifact = struct();
artifact.output_dir = output_dir;
artifact.file_name = file_name;
artifact.file_path = file_path;
artifact.latest_file_name = latest_file_name;
artifact.latest_file_path = latest_file_path;
artifact.row_count = height(table_obj);
artifact.col_count = width(table_obj);
artifact.timestamp = timestamp;
artifact.meta = struct('status', 'ok');
end
