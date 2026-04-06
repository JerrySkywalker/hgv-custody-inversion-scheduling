function stage02_info = load_stage02_trajectory_family(cfg)
%LOAD_STAGE02_TRAJECTORY_FAMILY Diagnose Stage02 trajectory artifacts only.
%
% Phase B1.2:
%   This function does NOT fully parse all legacy formats yet.
%   It scans likely Stage02 output folders and summarizes candidate MAT files.

if nargin < 1
    cfg = default_ch5b_params();
end

root_dir = cfg.path.root_dir;

candidate_dirs = { ...
    fullfile(root_dir, 'outputs', 'stage', 'stage02'), ...
    fullfile(root_dir, 'outputs', 'stages', 'stage02'), ...
    fullfile(root_dir, 'outputs', 'milestones', 'MA'), ...
    fullfile(root_dir, 'outputs')};

mat_files = {};

for i = 1:numel(candidate_dirs)
    d = candidate_dirs{i};
    if exist(d, 'dir')
        found = dir(fullfile(d, '**', '*.mat'));
        for k = 1:numel(found)
            mat_files{end+1,1} = fullfile(found(k).folder, found(k).name); %#ok<AGROW>
        end
    end
end

% unique preserve order
if isempty(mat_files)
    unique_files = {};
else
    [~, ia] = unique(mat_files, 'stable');
    unique_files = mat_files(sort(ia));
end

records = struct([]);
rec_idx = 0;

for i = 1:numel(unique_files)
    fp = unique_files{i};
    lower_fp = lower(fp);

    if contains(lower_fp, 'stage02') || contains(lower_fp, 'traj') || contains(lower_fp, 'truth')
        rec_idx = rec_idx + 1;
        records(rec_idx).file_path = fp; %#ok<AGROW>
        records(rec_idx).file_name = string(get_filename(fp)); %#ok<AGROW>

        try
            vars = whos('-file', fp);
            records(rec_idx).var_names = {vars.name}; %#ok<AGROW>
            records(rec_idx).var_count = numel(vars); %#ok<AGROW>
            records(rec_idx).bytes = sum([vars.bytes]); %#ok<AGROW>
            records(rec_idx).load_ok = true; %#ok<AGROW>
        catch ME
            records(rec_idx).var_names = {ME.message}; %#ok<AGROW>
            records(rec_idx).var_count = -1; %#ok<AGROW>
            records(rec_idx).bytes = -1; %#ok<AGROW>
            records(rec_idx).load_ok = false; %#ok<AGROW>
        end
    end
end

stage02_info = struct();
stage02_info.framework = 'ch5_bubble';
stage02_info.phase = 'B1.2';
stage02_info.scan_mode = 'diagnose_only';
stage02_info.root_dir = root_dir;
stage02_info.candidate_dirs = candidate_dirs;
stage02_info.total_candidate_mat_files = numel(unique_files);
stage02_info.records = records;
stage02_info.record_count = numel(records);
stage02_info.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

end

function name = get_filename(fp)
[~, name, ext] = fileparts(fp);
name = [name, ext];
end
