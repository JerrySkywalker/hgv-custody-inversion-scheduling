function out = pack_project_snapshot_core(opts)
if nargin < 1 || ~isstruct(opts)
    error('pack_project_snapshot_core:InvalidInput', ...
        'opts struct is required.');
end

required_fields = {'snapshot_name','source','content'};
for k = 1:numel(required_fields)
    f = required_fields{k};
    if ~isfield(opts, f)
        error('pack_project_snapshot_core:MissingOption', ...
            'Missing required opts field: %s', f);
    end
end

valid_sources = {'working','head'};
valid_contents = {'all','code'};

assert(any(strcmpi(opts.source, valid_sources)), ...
    'Invalid source. Expected working or head.');
assert(any(strcmpi(opts.content, valid_contents)), ...
    'Invalid content. Expected all or code.');

this_file = mfilename('fullpath');
pack_root = fileparts(this_file);
repo_root = fileparts(fileparts(pack_root));

settings_file = fullfile(pack_root, 'pack_project_snapshot_settings.json');
assert(exist(settings_file, 'file') == 2, ...
    'Settings file not found: %s', settings_file);
settings = jsondecode(fileread(settings_file));

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

snapshot_root = fullfile(repo_root, 'snapshots', opts.snapshot_name);
if ~exist(snapshot_root, 'dir')
    mkdir(snapshot_root);
end

staging_dir = fullfile(snapshot_root, [opts.snapshot_name '_staging_' timestamp]);
zip_name = [opts.snapshot_name '_' timestamp '.zip'];
zip_path = fullfile(snapshot_root, zip_name);

mkdir(staging_dir);

switch lower(opts.source)
    case 'working'
        pack_from_working_tree(repo_root, staging_dir, settings, opts);
    case 'head'
        pack_from_git_head(repo_root, staging_dir, settings, opts);
    otherwise
        error('pack_project_snapshot_core:InvalidSource', ...
            'Unsupported source: %s', opts.source);
end

write_snapshot_manifest(staging_dir, opts, created_at, timestamp);

file_count = count_files_recursive(staging_dir);
old_dir = pwd;
cd(snapshot_root);
zip(zip_name, [opts.snapshot_name '_staging_' timestamp]);
cd(old_dir);
rmdir(staging_dir, 's');

out = struct();
out.zip_path = zip_path;
out.snapshot_dir = snapshot_root;
out.file_count = file_count;
out.created_at = created_at;
out.meta = struct( ...
    'status', 'ok', ...
    'snapshot_name', opts.snapshot_name, ...
    'source', opts.source, ...
    'content', opts.content);

fprintf('[pack] Created snapshot: %s\n', zip_path);
end

function pack_from_working_tree(repo_root, staging_dir, settings, opts)
scan_dir_recursive(repo_root, repo_root, staging_dir, settings, opts);
end

function scan_dir_recursive(base_root, current_dir, staging_dir, settings, opts)
items = dir(current_dir);

for k = 1:numel(items)
    item = items(k);
    name = item.name;

    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end

    src_path = fullfile(current_dir, name);
    rel_path = make_relative_path(base_root, src_path);

    if item.isdir
        if should_skip_dir(rel_path, settings)
            continue;
        end
        scan_dir_recursive(base_root, src_path, staging_dir, settings, opts);
    else
        if should_include_file(rel_path, name, settings, opts)
            dst_path = fullfile(staging_dir, rel_path);
            dst_dir = fileparts(dst_path);
            if ~exist(dst_dir, 'dir')
                mkdir(dst_dir);
            end
            copyfile(src_path, dst_path);
        end
    end
end
end

function pack_from_git_head(repo_root, staging_dir, settings, opts)
old_dir = pwd;
cd(repo_root);
cleanupObj = onCleanup(@() cd(old_dir)); %#ok<NASGU>

tmp_id = char(java.util.UUID.randomUUID());
tmp_zip = fullfile(tempdir, ['pack_head_' tmp_id '.zip']);
tmp_extract_dir = fullfile(tempdir, ['pack_head_' tmp_id]);

if exist(tmp_zip, 'file') == 2
    delete(tmp_zip);
end
if exist(tmp_extract_dir, 'dir') == 7
    rmdir(tmp_extract_dir, 's');
end

mkdir(tmp_extract_dir);

cleanupTmp = onCleanup(@() cleanup_temp_head_artifacts(tmp_zip, tmp_extract_dir)); %#ok<NASGU>

cmd = sprintf('git archive --format=zip -o "%s" HEAD', tmp_zip);
[status, out] = system(cmd);
if status ~= 0
    error('pack_project_snapshot_core:GitArchiveFailed', ...
        'git archive failed:\n%s', out);
end

unzip(tmp_zip, tmp_extract_dir);

scan_dir_recursive(tmp_extract_dir, tmp_extract_dir, staging_dir, settings, opts);
end

function tf = should_skip_dir(rel_path, settings)
rel_norm = strrep(rel_path, '/', filesep);
parts = regexp(rel_norm, ['\' filesep], 'split');
parts = parts(~cellfun(@isempty, parts));

skip_dirs = normalize_to_cellstr(settings.skip_dirs);
tf = any(ismember(lower(parts), lower(skip_dirs)));
end

function tf = should_include_file(rel_path, name, settings, opts) %#ok<INUSD>
switch lower(opts.content)
    case 'all'
        tf = true;
    case 'code'
        tf = is_code_file(name, settings);
    otherwise
        tf = false;
end
end

function tf = is_code_file(name, settings)
[~,~,ext] = fileparts(name);

always_include_names = normalize_to_cellstr(settings.always_include_names);
if any(strcmpi(name, always_include_names))
    tf = true;
    return;
end

code_blocked_ext = normalize_to_cellstr(settings.code_blocked_ext);
if any(strcmpi(ext, code_blocked_ext))
    tf = false;
    return;
end

code_allowed_ext = normalize_to_cellstr(settings.code_allowed_ext);
tf = any(strcmpi(ext, code_allowed_ext));
end

function rel_path = make_relative_path(base_root, full_path)
base_root = char(java.io.File(base_root).getCanonicalPath());
full_path = char(java.io.File(full_path).getCanonicalPath());

if strncmpi(full_path, base_root, length(base_root))
    rel_path = full_path(length(base_root)+2:end);
else
    error('pack_project_snapshot_core:RelativePathFailed', ...
        'Failed to compute relative path.');
end
end

function write_snapshot_manifest(staging_dir, opts, created_at, timestamp)
manifest_path = fullfile(staging_dir, 'SNAPSHOT_MANIFEST.txt');
fid = fopen(manifest_path, 'w');
assert(fid > 0, 'Failed to write manifest.');

fprintf(fid, 'snapshot_name: %s\n', opts.snapshot_name);
fprintf(fid, 'source: %s\n', opts.source);
fprintf(fid, 'content: %s\n', opts.content);
fprintf(fid, 'created_at: %s\n', created_at);
fprintf(fid, 'timestamp: %s\n', timestamp);

fclose(fid);
end

function n = count_files_recursive(root_dir)
n = 0;
if exist(root_dir, 'dir') ~= 7
    return;
end

items = dir(root_dir);
for k = 1:numel(items)
    item = items(k);
    name = item.name;

    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end

    full_path = fullfile(root_dir, name);
    if item.isdir
        n = n + count_files_recursive(full_path);
    else
        n = n + 1;
    end
end
end

function cellstr_out = normalize_to_cellstr(v)
if iscell(v)
    cellstr_out = cellfun(@char, v, 'UniformOutput', false);
elseif isstring(v)
    cellstr_out = cellstr(v);
elseif ischar(v)
    cellstr_out = {v};
else
    cellstr_out = {};
end
end

function cleanup_temp_head_artifacts(tmp_zip, tmp_extract_dir)
if exist(tmp_zip, 'file') == 2
    try
        delete(tmp_zip);
    catch
    end
end

if exist(tmp_extract_dir, 'dir') == 7
    try
        rmdir(tmp_extract_dir, 's');
    catch
    end
end
end