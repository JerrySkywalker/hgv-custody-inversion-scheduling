function cleanup_MB_outputs(dry_run)
if nargin < 1
    dry_run = true;
end

startup;

target_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

if ~exist(target_dir, 'dir')
    fprintf('[cleanup] Target directory does not exist: %s\n', target_dir);
    return;
end

items = dir(target_dir);
removed_count = 0;
kept_count = 0;

fprintf('[cleanup] Target directory: %s\n', target_dir);
fprintf('[cleanup] dry_run = %d\n', dry_run);

for k = 1:numel(items)
    item = items(k);

    if item.isdir
        continue;
    end

    name = item.name;
    full_path = fullfile(target_dir, name);

    % Keep all latest artifacts
    if contains(name, '_latest.')
        fprintf('[keep] %s\n', name);
        kept_count = kept_count + 1;
        continue;
    end

    % Remove timestamped CSV/MAT/TXT artifacts
    if endsWith(name, '.csv') || endsWith(name, '.mat') || endsWith(name, '.txt')
        fprintf('[remove] %s\n', name);
        removed_count = removed_count + 1;

        if ~dry_run
            delete(full_path);
        end
        continue;
    end

    % Keep anything else by default
    fprintf('[keep] %s\n', name);
    kept_count = kept_count + 1;
end

fprintf('[cleanup] kept_count = %d\n', kept_count);
fprintf('[cleanup] removed_count = %d\n', removed_count);

if dry_run
    fprintf('[cleanup] Dry run only. No files were deleted.\n');
else
    fprintf('[cleanup] Deletion completed.\n');
end
end
