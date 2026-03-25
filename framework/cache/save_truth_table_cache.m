function cache_info = save_truth_table_cache(grid_table, meta, options)
%SAVE_TRUTH_TABLE_CACHE Save a truth-table cache with latest and timestamped copies.
% Inputs:
%   grid_table : truth table
%   meta       : cache meta struct
%   options    : optional struct with output_dir and cache_key

if nargin < 3 || isempty(options)
    options = struct();
end
if ~istable(grid_table)
    error('save_truth_table_cache:grid_table must be a table.');
end

if ~isfield(options, 'output_dir') || isempty(options.output_dir)
    options.output_dir = fullfile('outputs', 'framework', 'cache', 'truth');
end
ensure_dir(options.output_dir);

if ~isfield(options, 'cache_key') || isempty(options.cache_key)
    options.cache_key = make_cache_key(meta.source_kind, meta.engine_mode, meta.run_tag);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
cache_name = sprintf('%s_%s.mat', options.cache_key, timestamp);
latest_name = sprintf('%s_latest.mat', options.cache_key);
cache_path = fullfile(options.output_dir, cache_name);
latest_path = fullfile(options.output_dir, latest_name);

payload = struct();
payload.grid_table = grid_table;
payload.meta = meta;

save(cache_path, 'payload', '-v7.3');
save(latest_path, 'payload', '-v7.3');

manifest = make_cache_manifest('truth_table', cache_path, payload, meta);
manifest_mat_path = fullfile(options.output_dir, sprintf('%s_manifest_%s.mat', options.cache_key, timestamp));
manifest_txt_path = fullfile(options.output_dir, sprintf('%s_manifest_latest.txt', options.cache_key));
save(manifest_mat_path, 'manifest');
local_write_manifest_txt(manifest_txt_path, manifest);

cache_info = struct();
cache_info.cache_path = cache_path;
cache_info.latest_path = latest_path;
cache_info.manifest_mat_path = manifest_mat_path;
cache_info.manifest_txt_path = manifest_txt_path;
cache_info.cache_key = options.cache_key;
end

function local_write_manifest_txt(txt_path, manifest)
fid = fopen(txt_path, 'w');
if fid < 0
    error('save_truth_table_cache:FailedToOpenManifest', ...
        'Failed to open manifest file: %s', txt_path);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'cache_kind: %s\n', manifest.cache_kind);
fprintf(fid, 'cache_path: %s\n', manifest.cache_path);
fprintf(fid, 'created_at: %s\n', manifest.created_at);
fprintf(fid, 'row_count: %g\n', manifest.row_count);
fprintf(fid, 'col_count: %g\n', manifest.col_count);

meta_fields = fieldnames(manifest.meta);
for k = 1:numel(meta_fields)
    name = meta_fields{k};
    value = manifest.meta.(name);
    fprintf(fid, 'meta.%s: %s\n', name, local_value_to_string(value));
end
end

function s = local_value_to_string(value)
if isstring(value) || ischar(value)
    s = char(string(value));
elseif isnumeric(value) || islogical(value)
    s = mat2str(value);
elseif isstruct(value)
    s = '<struct>';
elseif istable(value)
    s = '<table>';
else
    s = sprintf('<%s>', class(value));
end
end
