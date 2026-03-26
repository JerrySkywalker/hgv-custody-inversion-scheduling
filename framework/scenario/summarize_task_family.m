function summary = summarize_task_family(task_family)
%SUMMARIZE_TASK_FAMILY Build a lightweight summary for a task family.

if ~isstruct(task_family) || ~isfield(task_family, 'items') || ~istable(task_family.items)
    error('summarize_task_family:InvalidTaskFamily', ...
        'task_family must be a valid task family struct.');
end

items = task_family.items;

summary = struct();
summary.family_name = task_family.family_name;
summary.source_registry_name = task_family.source_registry_name;
summary.selection_mode = task_family.selection_mode;
summary.item_count = height(items);

if isempty(items)
    summary.group_names = strings(0,1);
    summary.source_kinds = strings(0,1);
    summary.generator_ids = strings(0,1);
else
    summary.group_names = unique(string(items.group_name));
    summary.source_kinds = unique(string(items.source_kind));
    summary.generator_ids = unique(string(items.generator_id));
end
end
