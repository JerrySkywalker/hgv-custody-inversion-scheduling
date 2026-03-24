function out = pack_framework_snapshot_core(opts)
if nargin < 1 || ~isstruct(opts)
    error('pack_framework_snapshot_core:InvalidInput', ...
        'opts struct is required.');
end

required_fields = {'snapshot_name','scope','code_only','include_outputs','include_chapter5','include_legacy'};
for k = 1:numel(required_fields)
    f = required_fields{k};
    if ~isfield(opts, f)
        error('pack_framework_snapshot_core:MissingOption', ...
            'Missing required opts field: %s', f);
    end
end

this_file = mfilename('fullpath');
tools_pack_root = fileparts(this_file);
repo_root = fileparts(fileparts(tools_pack_root));

settings_file = fullfile(tools_pack_root, 'pack_framework_snapshot_settings.json');
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

copy_file_if_exists(fullfile(repo_root, 'startup.m'), fullfile(staging_dir, 'startup.m'));
copy_file_if_exists(fullfile(repo_root, 'README.md'), fullfile(staging_dir, 'README.md'));
copy_file_if_exists(fullfile(repo_root, 'CHANGELOG.md'), fullfile(staging_dir, 'CHANGELOG.md'));

copy_tree_filtered(fullfile(repo_root, 'tools', 'pack'), fullfile(staging_dir, 'tools', 'pack'), settings);
copy_tree_filtered(fullfile(repo_root, 'framework'), fullfile(staging_dir, 'framework'), settings);
copy_tree_filtered(fullfile(repo_root, 'experiments', 'common'), fullfile(staging_dir, 'experiments', 'common'), settings);
copy_tree_filtered(fullfile(repo_root, 'experiments', 'chapter4'), fullfile(staging_dir, 'experiments', 'chapter4'), settings);
copy_tree_filtered(fullfile(repo_root, 'tests', 'smoke'), fullfile(staging_dir, 'tests', 'smoke'), settings);

included_roots = {'tools/pack','framework','experiments/common','experiments/chapter4','tests/smoke'};

if opts.include_chapter5
    copy_tree_filtered(fullfile(repo_root, 'experiments', 'chapter5'), fullfile(staging_dir, 'experiments', 'chapter5'), settings);
    included_roots{end+1} = 'experiments/chapter5'; %#ok<AGROW>
end

if opts.include_legacy
    copy_tree_filtered(fullfile(repo_root, 'legacy'), fullfile(staging_dir, 'legacy'), settings);
    included_roots{end+1} = 'legacy'; %#ok<AGROW>
end

if opts.include_outputs && ~opts.code_only
    copy_latest_outputs(repo_root, staging_dir, opts, settings);
    if strcmpi(opts.scope, 'head')
        included_roots{end+1} = 'outputs/experiments/chapter4 (latest only)'; %#ok<AGROW>
    else
        included_roots{end+1} = 'outputs/experiments (latest only)'; %#ok<AGROW>
    end
end

write_snapshot_manifest(staging_dir, opts, created_at, timestamp, included_roots);

file_count = count_files_recursive(staging_dir);
zip(zip_path, staging_dir);
rmdir(staging_dir, 's');

out = struct();
out.zip_path = zip_path;
out.snapshot_dir = snapshot_root;
out.file_count = file_count;
out.created_at = created_at;
out.meta = struct('status', 'ok', 'snapshot_name', opts.snapshot_name);

fprintf('[pack] Created snapshot: %s\n', zip_path);
end

function copy_file_if_exists(src, dst)
if exist(src, 'file') == 2
    dst_dir = fileparts(dst);
    if ~exist(dst_dir, 'dir')
        mkdir(dst_dir);
    end
    copyfile(src, dst);
end
end

function copy_tree_filtered(src_root, dst_root, settings)
if exist(src_root, 'dir') ~= 7
    return;
end

items = dir(src_root);
for k = 1:numel(items)
    item = items(k);
    name = item.name;

    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end

    src_path = fullfile(src_root, name);
    dst_path = fullfile(dst_root, name);

    if item.isdir
        if should_skip_dir(name, settings)
            continue;
        end
        if ~exist(dst_path, 'dir')
            mkdir(dst_path);
        end
        copy_tree_filtered(src_path, dst_path, settings);
    else
        if should_copy_file(name, settings)
            dst_dir = fileparts(dst_path);
            if ~exist(dst_dir, 'dir')
                mkdir(dst_dir);
            end
            copyfile(src_path, dst_path);
        end
    end
end
end

function tf = should_skip_dir(name, settings)
skip_dirs = normalize_to_cellstr(settings.skip_dirs);
tf = any(strcmpi(name, skip_dirs));
end

function tf = should_copy_file(name, settings)
[~,~,ext] = fileparts(name);

allowed_ext = normalize_to_cellstr(settings.allowed_ext);
blocked_ext = normalize_to_cellstr(settings.blocked_ext);
blocked_names = normalize_to_cellstr(settings.blocked_names);

if any(strcmpi(name, blocked_names))
    tf = false;
    return;
end

if any(strcmpi(ext, blocked_ext))
    tf = false;
    return;
end

tf = any(strcmpi(ext, allowed_ext));
end

function copy_latest_outputs(repo_root, staging_dir, opts, settings)
if strcmpi(opts.scope, 'head')
    copy_latest_output_tree(fullfile(repo_root, 'outputs', 'experiments', 'chapter4'), ...
        fullfile(staging_dir, 'outputs', 'experiments', 'chapter4'), settings);
else
    copy_latest_output_tree(fullfile(repo_root, 'outputs', 'experiments'), ...
        fullfile(staging_dir, 'outputs', 'experiments'), settings);
end
end

function copy_latest_output_tree(src_root, dst_root, settings)
if exist(src_root, 'dir') ~= 7
    return;
end

items = dir(src_root);
for k = 1:numel(items)
    item = items(k);
    name = item.name;

    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end

    src_path = fullfile(src_root, name);
    dst_path = fullfile(dst_root, name);

    if item.isdir
        copy_latest_output_tree(src_path, dst_path, settings);
    else
        latest_pattern = char(settings.latest_pattern);
        if contains(name, latest_pattern)
            dst_dir = fileparts(dst_path);
            if ~exist(dst_dir, 'dir')
                mkdir(dst_dir);
            end
            copyfile(src_path, dst_path);
        end
    end
end
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

function out = normalize_to_cellstr(value)
if iscell(value)
    out = cellfun(@char, value, 'UniformOutput', false);
elseif isstring(value)
    out = cellstr(value);
elseif ischar(value)
    out = {value};
elseif isnumeric(value) && isempty(value)
    out = {};
else
    error('pack_framework_snapshot_core:UnsupportedSettingType', ...
        'Unsupported settings array type: %s', class(value));
end
end

function write_snapshot_manifest(staging_dir, opts, created_at, timestamp, included_roots)
manifest_path = fullfile(staging_dir, 'manifest.txt');
fid = fopen(manifest_path, 'w');
assert(fid ~= -1, 'Failed to create snapshot manifest: %s', manifest_path);

fprintf(fid, 'snapshot_name: %s\n', opts.snapshot_name);
fprintf(fid, 'scope: %s\n', opts.scope);
fprintf(fid, 'code_only: %d\n', logical(opts.code_only));
fprintf(fid, 'include_outputs: %d\n', logical(opts.include_outputs));
fprintf(fid, 'include_chapter5: %d\n', logical(opts.include_chapter5));
fprintf(fid, 'include_legacy: %d\n', logical(opts.include_legacy));
fprintf(fid, 'created_at: %s\n', created_at);
fprintf(fid, 'timestamp: %s\n', timestamp);
fprintf(fid, '\n');
fprintf(fid, 'included_roots:\n');
for k = 1:numel(included_roots)
    fprintf(fid, '  - %s\n', included_roots{k});
end

fclose(fid);
end
