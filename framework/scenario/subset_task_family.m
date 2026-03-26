function sub_family = subset_task_family(task_family, selector)
%SUBSET_TASK_FAMILY Build a subset from an existing task family.

if nargin < 2 || isempty(selector)
    selector = struct();
end

if ~isstruct(task_family) || ~isfield(task_family, 'items') || ~istable(task_family.items)
    error('subset_task_family:InvalidTaskFamily', ...
        'task_family must be a valid task family struct.');
end

tmp_registry = struct();
tmp_registry.registry_name = string(task_family.source_registry_name);
tmp_registry.items = task_family.items;

sub_family = build_task_family(tmp_registry, selector);
end
