function zipFilePath = pack_framework_snapshot_core(opts)
%PACK_FRAMEWORK_SNAPSHOT_CORE Create snapshot zip under snapshots/.
%
% Example:
%   zipFilePath = pack_framework_snapshot_core();
%   zipFilePath = pack_framework_snapshot_core(struct('mode','working'));
%   zipFilePath = pack_framework_snapshot_core(struct('mode','head','code_only',true));

    if nargin < 1 || isempty(opts)
        opts = struct();
    end

    opts = apply_defaults(opts);

    project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    snapshots_dir = fullfile(project_root, 'snapshots');
    if ~isfolder(snapshots_dir)
        mkdir(snapshots_dir);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    archive_name = sprintf('%s_%s.zip', timestamp, opts.archive_label);
    zipFilePath = fullfile(snapshots_dir, archive_name);

    staging_root = fullfile(tempdir, ['snapshot_stage_' char(java.util.UUID.randomUUID)]);
    mkdir(staging_root);

    cleanupObj = onCleanup(@() cleanup_staging(staging_root));

    fprintf('[pack_snapshot] project_root : %s\n', project_root);
    fprintf('[pack_snapshot] mode         : %s\n', opts.mode);
    fprintf('[pack_snapshot] code_only    : %d\n', opts.code_only);
    fprintf('[pack_snapshot] output       : %s\n', zipFilePath);

    switch lower(opts.mode)
        case 'working'
            collect_from_working_tree(project_root, staging_root, opts);
        case 'head'
            collect_from_git_head(project_root, staging_root, opts);
        otherwise
            error('pack_framework_snapshot_core:InvalidMode', ...
                'Unknown mode: %s', opts.mode);
    end

    old_dir = pwd;
    cd(staging_root);
    zip(zipFilePath, '.');
    cd(old_dir);

    fprintf('[pack_snapshot] created: %s\n', zipFilePath);
end

function opts = apply_defaults(opts)
    defaults = struct( ...
        'mode', 'working', ...              % 'working' or 'head'
        'code_only', false, ...
        'include_deliverables', false, ...
        'archive_label', 'snapshot');

    names = fieldnames(defaults);
    for i = 1:numel(names)
        name = names{i};
        if ~isfield(opts, name) || isempty(opts.(name))
            opts.(name) = defaults.(name);
        end
    end
end

function collect_from_working_tree(project_root, staging_root, opts)
    include_list = { ...
        'src', ...
        'run_stages', ...
        'milestones', ...
        'params', ...
        'tools', ...
        'tests', ...
        'startup.m', ...
        'README.md', ...
        'pack_snapshot_all.m', ...
        'pack_snapshot_all_code.m', ...
        'pack_snapshot_head.m', ...
        'pack_snapshot_head_code.m'};

    if opts.include_deliverables
        include_list{end+1} = 'deliverables';
    end

    for i = 1:numel(include_list)
        copy_item_if_exists(project_root, staging_root, include_list{i});
    end
end

function collect_from_git_head(project_root, staging_root, opts)
    tracked = git_ls_files(project_root);

    for i = 1:numel(tracked)
        rel = tracked{i};

        if startsWith(rel, 'outputs/') || startsWith(rel, 'snapshots/')
            continue;
        end

        if opts.code_only && startsWith(rel, 'deliverables/')
            continue;
        end

        copy_tracked_file(project_root, staging_root, rel);
    end
end

function files = git_ls_files(project_root)
    old_dir = pwd;
    cd(project_root);
    cleanupObj = onCleanup(@() cd(old_dir));

    [status, out] = system('git ls-files');
    if status ~= 0
        error('pack_framework_snapshot_core:GitLsFilesFailed', ...
            'git ls-files failed.');
    end

    lines = regexp(strtrim(out), '\r\n|\n|\r', 'split');
    lines = lines(~cellfun(@isempty, lines));
    files = lines;
end

function copy_item_if_exists(project_root, staging_root, rel_path)
    src = fullfile(project_root, rel_path);
    dst = fullfile(staging_root, rel_path);

    if isfolder(src)
        parent_dir = fileparts(dst);
        if ~isfolder(parent_dir)
            mkdir(parent_dir);
        end
        copyfile(src, dst);
        fprintf('[pack_snapshot] copied dir : %s\n', rel_path);
    elseif isfile(src)
        parent_dir = fileparts(dst);
        if ~isfolder(parent_dir)
            mkdir(parent_dir);
        end
        copyfile(src, dst);
        fprintf('[pack_snapshot] copied file: %s\n', rel_path);
    end
end

function copy_tracked_file(project_root, staging_root, rel_path)
    src = fullfile(project_root, rel_path);
    if ~isfile(src)
        return;
    end

    dst = fullfile(staging_root, rel_path);
    parent_dir = fileparts(dst);
    if ~isfolder(parent_dir)
        mkdir(parent_dir);
    end
    copyfile(src, dst);
end

function cleanup_staging(staging_root)
    if isfolder(staging_root)
        try
            rmdir(staging_root, 's');
        catch
        end
    end
end
