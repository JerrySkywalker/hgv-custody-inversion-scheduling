function summary = summarize_task_family(task_family)
%SUMMARIZE_TASK_FAMILY Build a lightweight summary for a task family.

if ~isstruct(task_family) || ~isfield(task_family, 'items') || ~istable(task_family.items)
    error('summarize_task_family:InvalidTaskFamily', ...
        'task_family must be a valid task family struct.');
end

items = task_family.items;

summary = struct();
if isfield(task_family, 'class_name')
    summary.class_name = task_family.class_name;
else
    summary.class_name = 'unknown';
end
summary.source_registry_name = task_family.source_registry_name;
summary.selection_mode = task_family.selection_mode;
summary.item_count = height(items);

if isempty(items)
    summary.bundle_ids = strings(0,1);
    summary.source_kinds = strings(0,1);
    summary.generator_ids = strings(0,1);
    summary.variation_kinds = strings(0,1);
else
    summary.bundle_ids = unique(string(items.bundle_id));
    summary.source_kinds = unique(string(items.source_kind));
    summary.generator_ids = unique(string(items.generator_id));
    summary.variation_kinds = unique(string(items.variation_kind));
end
end
