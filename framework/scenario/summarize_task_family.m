function summary = summarize_task_family(task_family)
%SUMMARIZE_TASK_FAMILY Build a compact summary for a task family / task set.

if ~isstruct(task_family) || ~isfield(task_family, 'items') || ~istable(task_family.items)
    error('summarize_task_family:InvalidInput', ...
        'task_family must be a struct with table field items.');
end

items = task_family.items;
summary = struct();
summary.item_count = height(items);

if isfield(task_family, 'selection_mode') && ~isempty(task_family.selection_mode)
    summary.selection_mode = char(string(task_family.selection_mode));
else
    summary.selection_mode = '';
end

if isempty(items)
    summary.class_name = 'empty';
    summary.class_counts = struct();
    summary.track_ids_head = strings(0,1);
    return;
end

classes = string(items.class_name);
uniq = unique(classes, 'stable');

if numel(uniq) == 1
    summary.class_name = char(uniq(1));
else
    summary.class_name = 'mixed';
end

class_counts = struct();
for i = 1:numel(uniq)
    key = matlab.lang.makeValidName(char(uniq(i)));
    class_counts.(key) = sum(classes == uniq(i));
end

summary.class_counts = class_counts;
summary.track_ids_head = string(items.traj_id(1:min(5,height(items))));
end
