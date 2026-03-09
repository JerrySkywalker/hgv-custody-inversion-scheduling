function zipFilePath = package_for_chatgpt_baseline()
%PACKAGE_FOR_CHATGPT_BASELINE  Create a code snapshot zip from current HEAD.
%
% Packages the version at the latest commit (stable baseline for ChatGPT).
% Includes params/, src/, stages/, and root-level tracked files.
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
%   zipPath = package_for_chatgpt_baseline();
%

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

    % Only include params, src, stages if present in HEAD
    wantDirs = {'params', 'src', 'stages'};
    dirs_in_head = wantDirs(ismember(wantDirs, topLevelDirs));
    archivePaths = [dirs_in_head, rootFiles];
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
