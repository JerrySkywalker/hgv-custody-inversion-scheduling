function zipFilePath = pack_snapshot_all(include_milestone_outputs, include_paper_reports, archive_label)
%PACK_SNAPSHOT_ALL  Create a code snapshot zip for ChatGPT (working tree).
%
% Packages the current working directory (unstable version: may contain
% uncommitted changes). Includes code, runners, benchmark/shared-scenario
% folders, and root files.
%
% Optional input:
%   include_milestone_outputs = false by default
%   true  -> include tracked paper-export outputs under outputs/
%   false -> include only lightweight paper markdown reports if present
%   include_paper_reports = true by default
%   true  -> include lightweight paper markdown reports when
%            include_milestone_outputs is false
%   false -> package code/root files only, with no outputs/ content
%   archive_label = 'working' by default
%   controls the zip filename suffix
%
% Filename:
%   yyyymmdd_HHMMSS_<branch>_working.zip
%
% Usage (from MATLAB):
%   zipPath = pack_snapshot_all();
%   zipPath = pack_snapshot_all(true);
%   zipPath = pack_snapshot_all(false, false);

    if nargin < 1 || isempty(include_milestone_outputs)
        include_milestone_outputs = false;
    end
    if nargin < 2 || isempty(include_paper_reports)
        include_paper_reports = true;
    end
    if nargin < 3 || isempty(archive_label)
        archive_label = 'working';
    end

    repo_root = fileparts(mfilename('fullpath'));
    original_cwd = pwd;
    cleanupObj = onCleanup(@() cd(original_cwd)); %#ok<NASGU>
    cd(repo_root);

    datePart  = datestr(now, 'yyyymmdd');
    timePart  = datestr(now, 'HHMMSS');
    branchPart = local_get_branch_name();
    zipName = sprintf('%s_%s_%s_%s.zip', datePart, timePart, branchPart, archive_label);

    % Save archive in the parent directory of the repository root
    parent_root = fileparts(repo_root);
    zipFilePath = fullfile(parent_root, zipName);

    % Collect directories to include
    dirs_to_include = { ...
        'params', 'src', 'stages', 'run_stages', ...
        'milestones', 'run_milestones', ...
        'shared_scenarios', 'run_shared_scenarios', ...
        'benchmarks'};
    include_list = {};

    for i = 1:numel(dirs_to_include)
        d = dirs_to_include{i};
        if exist(d, 'dir')
            include_list{end+1} = d; %#ok<AGROW>
        else
            warning('Directory "%s" does not exist and will be skipped.', d);
        end
    end

    % Collect root-level files (exclude directories and the zip itself)
    entries = dir(repo_root);
    for i = 1:numel(entries)
        name = entries(i).name;
        if entries(i).isdir
            continue;
        end
        if strcmp(name, zipName)
            continue;
        end
        include_list{end+1} = name; %#ok<AGROW>
    end

    if include_milestone_outputs || include_paper_reports
        include_list = [include_list, ...
            local_collect_paper_outputs(repo_root, include_milestone_outputs)]; %#ok<AGROW>
    end
    include_list = unique(include_list, 'stable');

    if isempty(include_list)
        error('No files or directories found to include in the archive.');
    end

    fprintf('Creating archive: %s\n', zipFilePath);
    zip(zipFilePath, include_list);
    fprintf('Archive created with %d top-level entries.\n', numel(include_list));
end

function include_list = local_collect_paper_outputs(repo_root, include_milestone_outputs)
    include_list = {};
    outputs_dir = fullfile(repo_root, 'outputs');
    if ~exist(outputs_dir, 'dir')
        return;
    end

    if include_milestone_outputs
        paper_dirs = {'milestones', 'shared_scenarios', 'stage13'};
        for k = 1:numel(paper_dirs)
            paper_dir = fullfile(outputs_dir, paper_dirs{k});
            if exist(paper_dir, 'dir')
                include_list{end+1} = fullfile('outputs', paper_dirs{k}); %#ok<AGROW>
            end
        end
        return;
    end

    summary_file = fullfile(outputs_dir, 'milestones', 'milestone_summary_report.md');
    if exist(summary_file, 'file')
        include_list{end+1} = fullfile('outputs', 'milestones', 'milestone_summary_report.md'); %#ok<AGROW>
    end

    markdown_patterns = { ...
        fullfile(outputs_dir, 'milestones', '**', 'reports', '*.md'), ...
        fullfile(outputs_dir, 'shared_scenarios', '**', 'reports', '*.md'), ...
        fullfile(outputs_dir, 'stage13', 'reports', '*.md')};

    for i = 1:numel(markdown_patterns)
        report_files = dir(markdown_patterns{i});
        for k = 1:numel(report_files)
            rel_path = strrep(fullfile(report_files(k).folder, report_files(k).name), [repo_root filesep], '');
            include_list{end+1} = rel_path; %#ok<AGROW>
        end
    end
end

function branchPart = local_get_branch_name()
    [status, branchOut] = system('git branch --show-current');
    if status ~= 0
        branchPart = 'unknown-branch';
        return;
    end

    branchPart = strtrim(branchOut);
    if isempty(branchPart)
        branchPart = 'detached-head';
    end

    branchPart = regexprep(branchPart, '[^A-Za-z0-9._-]+', '-');
    branchPart = regexprep(branchPart, '-+', '-');
    branchPart = regexprep(branchPart, '^-|-$', '');
    if isempty(branchPart)
        branchPart = 'detached-head';
    end
end
