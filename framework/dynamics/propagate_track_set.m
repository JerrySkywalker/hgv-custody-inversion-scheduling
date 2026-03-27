function trajectory_set = propagate_track_set(task_set, cfg)
%PROPAGATE_TRACK_SET Propagate all tracks in a task set using Stage02 framework.
%
%   trajectory_set = PROPAGATE_TRACK_SET(task_set, cfg)

if nargin < 2
    error('propagate_track_set:NotEnoughInputs', ...
        'task_set and cfg are required.');
end

if ~isstruct(task_set) || ~isfield(task_set, 'items') || ~istable(task_set.items)
    error('propagate_track_set:InvalidTaskSet', ...
        'task_set must be a struct with table field items.');
end

items = task_set.items;
n = height(items);

track_ids = strings(n,1);
class_name = strings(n,1);
target_cfgs = cell(n,1);
trajectories = cell(n,1);
ok_flags = false(n,1);
error_messages = strings(n,1);

for k = 1:n
    track_i = items(k,:);
    track_ids(k) = string(track_i.traj_id);
    class_name(k) = string(track_i.class_name);

    try
        target_cfg_i = build_target_cfg_from_track(track_i, cfg);
        traj_i = propagate_single_track(target_cfg_i);

        target_cfgs{k} = target_cfg_i;
        trajectories{k} = traj_i;
        ok_flags(k) = true;
        error_messages(k) = "";
    catch ME
        target_cfgs{k} = [];
        trajectories{k} = [];
        ok_flags(k) = false;
        error_messages(k) = string(ME.message);
    end
end

trajectory_set = struct();
trajectory_set.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
trajectory_set.count = n;
trajectory_set.track_ids = track_ids;
trajectory_set.class_name = class_name;
trajectory_set.target_cfgs = target_cfgs;
trajectory_set.trajectories = trajectories;
trajectory_set.ok_flags = ok_flags;
trajectory_set.error_messages = error_messages;
end
