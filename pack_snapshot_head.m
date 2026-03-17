function zipFilePath = package_for_chatgpt_baseline(includeDeliverables, include_milestone_outputs)
%PACKAGE_FOR_CHATGPT_BASELINE  Create a code snapshot zip from current HEAD.
%
% Packages the version at the latest commit (stable baseline for ChatGPT).
% Includes params/, src/, stages/, run_stages/, milestones/, run_milestones/,
% and root-level tracked files. Excludes local generated outputs/ by default.
% deliverables/ is excluded by default; set optional argument to true to
% include it. Set include_milestone_outputs=true to include tracked
% outputs/ paper-export files as well.
%
% Filename:
%   yyyymmdd_HHMMSS_head.zip
%
% Usage (from MATLAB):
%   zipPath = package_for_chatgpt_baseline();                % deliverables excluded
%   zipPath = package_for_chatgpt_baseline(false);           % same
%   zipPath = package_for_chatgpt_baseline(true);            % include deliverables/
%   zipPath = package_for_chatgpt_baseline(false, true);     % include tracked milestone outputs
%

    if nargin < 1 || isempty(includeDeliverables)
        includeDeliverables = false;
    end
    if nargin < 2 || isempty(include_milestone_outputs)
        include_milestone_outputs = false;
    end

    repo_root = fileparts(mfilename('fullpath'));
    original_cwd = pwd;
    cleanupObj = onCleanup(@() cd(original_cwd)); %#ok<NASGU>
    cd(repo_root);

    datePart  = datestr(now, 'yyyymmdd');
    timePart  = datestr(now, 'HHMMSS');
    zipName = sprintf('%s_%s_head.zip', datePart, timePart);

    % Save archive in the parent directory of the repository root
    parent_root = fileparts(repo_root);
    zipFilePath = fullfile(parent_root, zipName);

    [status, treeOut] = system('git ls-tree --name-only HEAD');
    if status ~= 0
        error('Failed to run git ls-tree. Ensure git is installed and this folder is a git repository.');
    end

    lines = regexp(strtrim(treeOut), '\r?\n', 'split');
    rootFiles = {};
    topLevelDirs = {};
    for k = 1:numel(lines)
        name = strtrim(lines{k});
        if isempty(name)
            continue;
        end
        idx = regexp(name, '[/\\]', 'once');
        if isempty(idx)
            rootFiles{end+1} = name; %#ok<AGROW>
        else
            top = name(1:idx(1)-1);
            if ~ismember(top, topLevelDirs)
                topLevelDirs{end+1} = top; %#ok<AGROW>
            end
        end
    end

    % Only include code directories by default; deliverables/ and outputs/
    % are opt-in so local/generated assets stay out of baseline snapshots.
    wantDirs = {'params', 'src', 'stages', 'run_stages', 'milestones', 'run_milestones'};
    if includeDeliverables && ismember('deliverables', topLevelDirs)
        wantDirs{end+1} = 'deliverables'; %#ok<AGROW>
    end
    if include_milestone_outputs && ismember('outputs', topLevelDirs)
        wantDirs{end+1} = 'outputs'; %#ok<AGROW>
    end
    dirs_in_head = wantDirs(ismember(wantDirs, topLevelDirs));

    % Root entries with no path separator: may be files OR directory trees (e.g. results, deliverables).
    % Include only actual root files; exclude any name that is a top-level dir we did not ask for.
    rootFilesOnly = rootFiles(~ismember(rootFiles, topLevelDirs));
    archivePaths = [dirs_in_head, rootFilesOnly];

    % Explicitly exclude legacy results/ and local outputs/ roots unless requested.
    excludeNames = {'results'};
    if ~includeDeliverables
        excludeNames{end+1} = 'deliverables'; %#ok<AGROW>
    end
    if ~include_milestone_outputs
        excludeNames{end+1} = 'outputs'; %#ok<AGROW>
    end
    keep = cellfun(@(p) ~ismember(p, excludeNames), archivePaths);
    archivePaths = archivePaths(keep);

    if isempty(archivePaths)
        error('No paths to include in baseline archive.');
    end

    % Quote paths for shell (handles spaces)
    quoted = cell(1, numel(archivePaths));
    for k = 1:numel(archivePaths)
        quoted{k} = ['"' strrep(archivePaths{k}, '"', '\"') '"'];
    end
    pathList = strjoin(quoted, ' ');

    % git archive from HEAD
    zipPathQuoted = ['"' strrep(zipFilePath, '"', '\"') '"'];
    cmd = sprintf('git archive -o %s HEAD -- %s', zipPathQuoted, pathList);
    [status, errOut] = system(cmd);
    if status ~= 0
        error('git archive failed: %s', errOut);
    end

    fprintf('Baseline archive created: %s\n', zipFilePath);
    fprintf('Included %d paths from HEAD.\n', numel(archivePaths));
end
