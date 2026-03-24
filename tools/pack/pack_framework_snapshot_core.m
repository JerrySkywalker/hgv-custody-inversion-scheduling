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

repo_root = fileparts(mfilename('fullpath'));
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

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

copy_root_m_file_if_exists(repo_root, 'pack_framework_snapshot_core.m', staging_dir);
copy_root_m_file_if_exists(repo_root, 'pack_framework_snapshot_all.m', staging_dir);
copy_root_m_file_if_exists(repo_root, 'pack_framework_snapshot_all_code.m', staging_dir);
copy_root_m_file_if_exists(repo_root, 'pack_framework_snapshot_head.m', staging_dir);
copy_root_m_file_if_exists(repo_root, 'pack_framework_snapshot_head_code.m', staging_dir);

copy_tree_filtered(fullfile(repo_root, 'framework'), fullfile(staging_dir, 'framework'));
copy_tree_filtered(fullfile(repo_root, 'experiments', 'common'), fullfile(staging_dir, 'experiments', 'common'));
copy_tree_filtered(fullfile(repo_root, 'experiments', 'chapter4'), fullfile(staging_dir, 'experiments', 'chapter4'));
copy_tree_filtered(fullfile(repo_root, 'tests', 'smoke'), fullfile(staging_dir, 'tests', 'smoke'));

if opts.include_chapter5
    copy_tree_filtered(fullfile(repo_root, 'experiments', 'chapter5'), fullfile(staging_dir, 'experiments', 'chapter5'));
end

if opts.include_legacy
    copy_tree_filtered(fullfile(repo_root, 'legacy'), fullfile(staging_dir, 'legacy'));
end

if opts.include_outputs && ~opts.code_only
    copy_latest_outputs(repo_root, staging_dir, opts);
end

zip(zip_path, staging_dir);
rmdir(staging_dir, 's');

out = struct();
out.zip_path = zip_path;
out.snapshot_dir = snapshot_root;
out.file_count = count_files_in_zip_staging(repo_root, opts); %#ok<NASGU>
out.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
out.meta = struct('status', 'ok', 'snapshot_name', opts.snapshot_name);

fprintf('[pack] Created snapshot: %s\n', zip_path);
end

function copy_root_m_file_if_exists(repo_root, file_name, staging_dir)
src = fullfile(repo_root, file_name);
dst = fullfile(staging_dir, file_name);
copy_file_if_exists(src, dst);
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

function copy_tree_filtered(src_root, dst_root)
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
        if should_skip_dir(name)
            continue;
        end
        if ~exist(dst_path, 'dir')
            mkdir(dst_path);
        end
        copy_tree_filtered(src_path, dst_path);
    else
        if should_copy_file(name)
            dst_dir = fileparts(dst_path);
            if ~exist(dst_dir, 'dir')
                mkdir(dst_dir);
            end
            copyfile(src_path, dst_path);
        end
    end
end
end

function tf = should_skip_dir(name)
skip_dirs = {'.git','.vs','.vscode','snapshots'};
tf = any(strcmpi(name, skip_dirs));
end

function tf = should_copy_file(name)
[~,~,ext] = fileparts(name);

allowed_ext = {'.m','.md','.txt','.yaml','.yml','.json','.csv'};
blocked_names = {'.gitkeep'};
blocked_ext = {'.asv','.fig','.png','.jpg','.jpeg','.zip','.mat'};

if any(strcmpi(name, blocked_names))
    tf = true;
    return;
end

if any(strcmpi(ext, blocked_ext))
    tf = false;
    return;
end

tf = any(strcmpi(ext, allowed_ext));
end

function copy_latest_outputs(repo_root, staging_dir, opts)
if strcmpi(opts.scope, 'head')
    copy_latest_output_tree(fullfile(repo_root, 'outputs', 'experiments', 'chapter4'), ...
        fullfile(staging_dir, 'outputs', 'experiments', 'chapter4'));
else
    copy_latest_output_tree(fullfile(repo_root, 'outputs', 'experiments'), ...
        fullfile(staging_dir, 'outputs', 'experiments'));
end
end

function copy_latest_output_tree(src_root, dst_root)
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
        copy_latest_output_tree(src_path, dst_path);
    else
        if contains(name, '_latest.')
            dst_dir = fileparts(dst_path);
            if ~exist(dst_dir, 'dir')
                mkdir(dst_dir);
            end
            copyfile(src_path, dst_path);
        end
    end
end
end

function n = count_files_in_zip_staging(~, ~)
n = NaN;
end
