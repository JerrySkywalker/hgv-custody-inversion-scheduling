function zipFilePath = package_for_chatgpt_baseline(includeDeliverables)
%PACKAGE_FOR_CHATGPT_BASELINE  Create a code snapshot zip from current HEAD.
%
% Packages the version at the latest commit (stable baseline for ChatGPT).
% Includes params/, src/, stages/, root-level tracked files. Excludes results/
% (outputs and logs). deliverables/ is excluded by default; set optional
% argument to true to include it.
%
% Filename:
%   [StageXX.Y]_SHA7_yyyymmdd_HHMMSS_baseline.zip
%
%   - [StageXX.Y]: latest [Stage...] marker in the current branch log
%   - SHA7      : short SHA (7 chars) of the current HEAD commit
%   - yyyymmdd  : current date
%   - HHMMSS    : current time
%
% Usage (from MATLAB):
%   zipPath = package_for_chatgpt_baseline();           % deliverables excluded
%   zipPath = package_for_chatgpt_baseline(false);     % same
%   zipPath = package_for_chatgpt_baseline(true);      % include deliverables/
%

    if nargin < 1 || isempty(includeDeliverables)
        includeDeliverables = false;
    end

    repo_root = fileparts(mfilename('fullpath'));
    original_cwd = pwd;
    cleanupObj = onCleanup(@() cd(original_cwd)); %#ok<NASGU>
    cd(repo_root);

    stageLabel = detect_stage_label();
    shaShort  = detect_head_sha();
    datePart  = datestr(now, 'yyyymmdd');
    timePart  = datestr(now, 'HHMMSS');
    zipName = sprintf('%s_%s_%s_%s_baseline.zip', stageLabel, shaShort, datePart, timePart);

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

    % Only include these directories: never results/; deliverables/ only if requested
    wantDirs = {'params', 'src', 'stages'};
    if includeDeliverables && ismember('deliverables', topLevelDirs)
        wantDirs{end+1} = 'deliverables'; %#ok<AGROW>
    end
    dirs_in_head = wantDirs(ismember(wantDirs, topLevelDirs));

    % Root entries with no path separator: may be files OR directory trees (e.g. results, deliverables).
    % Include only actual root files; exclude any name that is a top-level dir we did not ask for.
    rootFilesOnly = rootFiles(~ismember(rootFiles, topLevelDirs));
    archivePaths = [dirs_in_head, rootFilesOnly];

    % Explicitly exclude results/ and (unless requested) deliverables/ from the archive
    excludeNames = {'results'};
    if ~includeDeliverables
        excludeNames{end+1} = 'deliverables'; %#ok<AGROW>
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


function stageLabel = detect_stage_label()
%DETECT_STAGE_LABEL  Get latest [StageXX.Y] label from current branch log.

    [status, out] = system('git log --format=%s');
    if status ~= 0
        error('Failed to query git log. Ensure git is installed and this folder is a git repository.');
    end

    lines = regexp(strtrim(out), '\r?\n', 'split');

    stageLabel = '[Stage]';

    for i = 1:numel(lines)
        line = strtrim(lines{i});
        % Look for a [Stage...] marker anywhere in the subject
        match = regexp(line, '\[Stage[^\]]*\]', 'match', 'once');
        if ~isempty(match)
            stageLabel = match;
            return;
        end
    end
end


function shaShort = detect_head_sha()
%DETECT_HEAD_SHA  Get short SHA (7 chars) of current HEAD commit.

    [status, out] = system('git rev-parse --short HEAD');
    if status ~= 0
        error('Failed to query git rev-parse. Ensure git is installed and this folder is a git repository.');
    end
    shaShort = strtrim(out);
end
