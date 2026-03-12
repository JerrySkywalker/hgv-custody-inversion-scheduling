function zipFilePath = package_for_chatgpt()
%PACKAGE_FOR_CHATGPT  Create a code snapshot zip for ChatGPT (working tree).
%
% Packages the current working directory (unstable version: may contain
% uncommitted changes). Includes params/, src/, stages/, and root files.
%
% Filename:
%   [StageXX.Y]_SHA7_yyyymmdd_HHMMSS_working.zip
%
%   - [StageXX.Y]: latest [Stage...] marker in the current branch log
%   - SHA7      : short SHA (7 chars) of the current HEAD commit
%   - yyyymmdd  : current date
%   - HHMMSS    : current time
%
% Usage (from MATLAB):
%   zipPath = package_for_chatgpt();
%

    repo_root = fileparts(mfilename('fullpath'));
    original_cwd = pwd;
    cleanupObj = onCleanup(@() cd(original_cwd)); %#ok<NASGU>
    cd(repo_root);

    stageLabel = detect_stage_label();
    shaShort  = detect_head_sha();
    datePart  = datestr(now, 'yyyymmdd');
    timePart  = datestr(now, 'HHMMSS');
    zipName = sprintf('%s_%s_%s_%s_working.zip', stageLabel, shaShort, datePart, timePart);

    % Save archive in the parent directory of the repository root
    parent_root = fileparts(repo_root);
    zipFilePath = fullfile(parent_root, zipName);

    % Collect directories to include
    dirs_to_include = {'params', 'src', 'stages', 'run_stages'};
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

    if isempty(include_list)
        error('No files or directories found to include in the archive.');
    end

    fprintf('Creating archive: %s\n', zipFilePath);
    zip(zipFilePath, include_list);
    fprintf('Archive created with %d top-level entries.\n', numel(include_list));
end


function stageLabel = detect_stage_label()
%DETECT_STAGE_LABEL  Get latest [StageXX.Y] label from current branch log.

    [status, out] = system('git log --format=%s');
    if status ~= 0
        error('Failed to query git log. Ensure git is installed and this folder is a git repository.');
    end

    lines = regexp(strtrim(out), '\r?\n', 'split');

    % Default fallback if no [Stage...] marker is found
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

