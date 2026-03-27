function summary = clean_outputs(varargin)
%CLEAN_OUTPUTS Safe cleanup utility for outputs/ directory.
%
% Usage examples:
%   clean_outputs()
%   clean_outputs('execute', true)
%   clean_outputs('targets', {'stage','logs'})
%   clean_outputs('execute', true, 'remove_empty_dirs', true)
%
% Targets:
%   'stage'             -> outputs/stage
%   'milestone'         -> outputs/milestone
%   'shared_scenarios'  -> outputs/shared_scenarios
%   'logs'              -> outputs/logs
%   'all'               -> all known targets
%
% Default behavior is dry-run.

    p = inputParser;
    addParameter(p, 'execute', false, @(x)islogical(x) || isnumeric(x));
    addParameter(p, 'targets', {'all'}, @(x)iscell(x) || isstring(x) || ischar(x));
    addParameter(p, 'remove_empty_dirs', false, @(x)islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    opts = p.Results;
    execute = logical(opts.execute);
    remove_empty_dirs = logical(opts.remove_empty_dirs);

    root_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputs_dir = fullfile(root_dir, 'outputs');

    target_map = get_target_map(outputs_dir);
    targets = normalize_targets(opts.targets, target_map);

    fprintf('[clean_outputs] root_dir    : %s\n', root_dir);
    fprintf('[clean_outputs] outputs_dir : %s\n', outputs_dir);
    fprintf('[clean_outputs] mode        : %s\n', ternary(execute, 'EXECUTE', 'DRY-RUN'));
    fprintf('[clean_outputs] targets     : %s\n', strjoin(targets, ', '));

    summary = struct();
    summary.root_dir = root_dir;
    summary.outputs_dir = outputs_dir;
    summary.execute = execute;
    summary.targets = targets;
    summary.items = struct([]);

    item_idx = 0;
    for i = 1:numel(targets)
        key = targets{i};
        target_dir = target_map.(key);

        if ~isfolder(target_dir)
            fprintf('[clean_outputs] skip missing target: %s\n', target_dir);
            continue;
        end

        entries = dir(target_dir);
        entries = entries(~ismember({entries.name}, {'.', '..'}));

        if isempty(entries)
            fprintf('[clean_outputs] target already empty: %s\n', target_dir);
            continue;
        end

        for j = 1:numel(entries)
            item_idx = item_idx + 1;
            entry = entries(j);
            abs_path = fullfile(entry.folder, entry.name);

            summary.items(item_idx).target = key; %#ok<AGROW>
            summary.items(item_idx).path = abs_path; %#ok<AGROW>
            summary.items(item_idx).isdir = entry.isdir; %#ok<AGROW>
            summary.items(item_idx).deleted = false; %#ok<AGROW>
            summary.items(item_idx).error = ''; %#ok<AGROW>

            if execute
                try
                    if entry.isdir
                        rmdir(abs_path, 's');
                    else
                        delete(abs_path);
                    end
                    summary.items(item_idx).deleted = true;
                    fprintf('[clean_outputs] deleted: %s\n', abs_path);
                catch ME
                    summary.items(item_idx).error = ME.message;
                    fprintf('[clean_outputs] FAILED : %s\n', abs_path);
                    fprintf('[clean_outputs] reason : %s\n', ME.message);
                end
            else
                fprintf('[clean_outputs] would delete: %s\n', abs_path);
            end
        end

        if execute && remove_empty_dirs
            prune_empty_dirs(target_dir);
        end
    end

    if isempty(summary.items)
        fprintf('[clean_outputs] nothing to clean.\n');
    end
end

function target_map = get_target_map(outputs_dir)
    target_map = struct();
    target_map.stage = fullfile(outputs_dir, 'stage');
    target_map.milestone = fullfile(outputs_dir, 'milestone');
    target_map.shared_scenarios = fullfile(outputs_dir, 'shared_scenarios');
    target_map.logs = fullfile(outputs_dir, 'logs');
end

function targets = normalize_targets(raw_targets, target_map)
    if ischar(raw_targets) || isstring(raw_targets)
        raw_targets = cellstr(raw_targets);
    end

    raw_targets = cellfun(@char, raw_targets, 'UniformOutput', false);
    raw_targets = cellfun(@lower, raw_targets, 'UniformOutput', false);

    if any(strcmp(raw_targets, 'all'))
        targets = fieldnames(target_map).';
        return;
    end

    valid = fieldnames(target_map);
    bad = setdiff(raw_targets, valid);
    if ~isempty(bad)
        error('clean_outputs:InvalidTarget', ...
            'Unknown target(s): %s', strjoin(bad, ', '));
    end

    targets = raw_targets;
end

function prune_empty_dirs(base_dir)
    listing = dir(base_dir);
    subdirs = listing([listing.isdir]);
    subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));

    for i = 1:numel(subdirs)
        child = fullfile(subdirs(i).folder, subdirs(i).name);
        prune_empty_dirs(child);
    end

    listing2 = dir(base_dir);
    listing2 = listing2(~ismember({listing2.name}, {'.', '..'}));
    if isempty(listing2)
        try
            rmdir(base_dir);
            fprintf('[clean_outputs] removed empty dir: %s\n', base_dir);
        catch
        end
    end
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end
