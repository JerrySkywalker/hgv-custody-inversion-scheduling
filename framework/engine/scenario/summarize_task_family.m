function summary = summarize_task_family(task_family)
%SUMMARIZE_TASK_FAMILY Summarize a task-family struct for cache/meta usage.
% Input:
%   task_family : struct with .trajs_in and optional .name
%
% Output:
%   summary     : struct with compact family metadata

summary = struct();
summary.name = '';
summary.case_count = 0;
summary.case_list = strings(0, 1);
summary.heading_offsets_deg = [];
summary.family_labels = strings(0, 1);

if nargin < 1 || isempty(task_family)
    return;
end

if isfield(task_family, 'name')
    summary.name = char(string(task_family.name));
elseif isfield(task_family, 'family_name')
    summary.name = char(string(task_family.family_name));
end

if ~isfield(task_family, 'trajs_in') || isempty(task_family.trajs_in)
    return;
end

trajs_in = task_family.trajs_in;
summary.case_count = numel(trajs_in);

case_list = strings(numel(trajs_in), 1);
family_labels = strings(numel(trajs_in), 1);
heading_offsets = nan(numel(trajs_in), 1);

for k = 1:numel(trajs_in)
    if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'case_id')
        case_list(k) = string(trajs_in(k).case.case_id);
    end
    if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'family')
        family_labels(k) = string(trajs_in(k).case.family);
    end
    if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'heading_offset_deg')
        heading_offsets(k) = trajs_in(k).case.heading_offset_deg;
    end
end

summary.case_list = case_list;
summary.family_labels = unique(family_labels);
summary.heading_offsets_deg = heading_offsets(isfinite(heading_offsets));
end
