function out = pack_project_snapshot_core(opts)
if nargin < 1 || ~isstruct(opts)
    error('pack_project_snapshot_core:InvalidInput', ...
        'opts struct is required.');
end

required_fields = {'snapshot_name','scope','code_only','include_outputs','include_chapter5','include_legacy'};
for k = 1:numel(required_fields)
    f = required_fields{k};
    if ~isfield(opts, f)
        error('pack_project_snapshot_core:MissingOption', ...
            'Missing required opts field: %s', f);
    end
end

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

% root files
root_files = normalize_to_cellstr(settings.root_files);
for i = 1:numel(root_files)
    rel = root_files{i};
    copy_file_if_exists(fullfile(repo_root, rel), fullfile(staging_dir, rel));
end

% common roots
roots_common = normalize_to_cellstr(settings.roots_common);
for i = 1:numel(roots_common)
    rel = roots_common{i};
    copy_tree_filtered(fullfile(repo_root, rel), fullfile(staging_dir, rel), settings);
end

% chapter 4 tex
chapter4_tex = normalize_to_cellstr(settings.chapter4_tex);
for i = 1:numel(chapter4_tex)
    name = chapter4_tex{i};
    copy_file_if_exists(fullfile(repo_root, name), fullfile(staging_dir, name));
end

% chapter 5 tex
if opts.include_chapter5
    chapter5_tex = normalize_to_cellstr(settings.chapter5_tex);
    for i = 1:numel(chapter5_tex)
        name = chapter5_tex{i};
        copy_file_if_exists(fullfile(repo_root, name), fullfile(staging_dir, name));
    end
end

% legacy
if opts.include_legacy
    copy_tree_filtered(fullfile(repo_root, 'legacy'), fullfile(staging_dir, 'legacy'), settings);
end

% outputs
if opts.include_outputs && ~opts.code_only
    copy_selected_outputs(repo_root, staging_dir, settings);
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

if isempty(ext)
    tf = any(strcmpi(name, allowed_ext));
    return;
end

tf = any(strcmpi(ext, allowed_ext));
end

function copy_selected_outputs(repo_root, staging_dir, settings)
copy_latest_output_tree(fullfile(repo_root, 'outputs', 'stage'), ...
    fullfile(staging_dir, 'outputs', 'stage'), settings);
copy_latest_output_tree(fullfile(repo_root, 'outputs', 'milestone'), ...
    fullfile(staging_dir, 'outputs', 'milestone'), settings);
copy_latest_output_tree(fullfile(repo_root, 'outputs', 'shared_scenarios'), ...
    fullfile(staging_dir, 'outputs', 'shared_scenarios'), settings);
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

function write_snapshot_manifest(staging_dir, opts, created_at, timestamp)
manifest_path = fullfile(staging_dir, 'SNAPSHOT_MANIFEST.txt');
fid = fopen(manifest_path, 'w');
assert(fid > 0, 'Failed to write manifest.');

fprintf(fid, 'snapshot_name: %s\n', opts.snapshot_name);
fprintf(fid, 'scope: %s\n', opts.scope);
fprintf(fid, 'code_only: %d\n', logical(opts.code_only));
fprintf(fid, 'include_outputs: %d\n', logical(opts.include_outputs));
fprintf(fid, 'include_chapter5: %d\n', logical(opts.include_chapter5));
fprintf(fid, 'include_legacy: %d\n', logical(opts.include_legacy));
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
