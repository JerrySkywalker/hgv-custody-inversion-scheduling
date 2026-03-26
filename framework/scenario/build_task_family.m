function task_family = build_task_family(registry, selector)
%BUILD_TASK_FAMILY Build a task family from a trajectory registry.
%
%   task_family = BUILD_TASK_FAMILY(registry)
%   task_family = BUILD_TASK_FAMILY(registry, selector)
%
%   selector is a struct with optional fields:
%     - family_name
%     - group_name
%     - source_kind
%     - generator_id
%     - traj_id
%     - selection_mode

if nargin < 2 || isempty(selector)
    selector = struct();
end

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('build_task_family:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

items = registry.items;

if isfield(selector, 'family_name') && ~isempty(selector.family_name)
    items = items(string(items.family_name) == string(selector.family_name), :);
end

if isfield(selector, 'group_name') && ~isempty(selector.group_name)
    items = items(string(items.group_name) == string(selector.group_name), :);
end

if isfield(selector, 'source_kind') && ~isempty(selector.source_kind)
    items = items(string(items.source_kind) == string(selector.source_kind), :);
end

if isfield(selector, 'generator_id') && ~isempty(selector.generator_id)
    items = items(string(items.generator_id) == string(selector.generator_id), :);
end

if isfield(selector, 'traj_id') && ~isempty(selector.traj_id)
    wanted_ids = string(selector.traj_id(:));
    items = items(ismember(string(items.traj_id), wanted_ids), :);
end

task_family = struct();
task_family.family_name = infer_family_name(items, selector);
task_family.source_registry_name = char(registry.registry_name);
task_family.selection_mode = infer_selection_mode(selector);
task_family.selector = selector;
task_family.items = items;
task_family.item_count = height(items);
task_family.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end

function name = infer_family_name(items, selector)
if isfield(selector, 'family_name') && ~isempty(selector.family_name)
    name = char(string(selector.family_name));
elseif isempty(items)
    name = 'empty';
else
    vals = unique(string(items.family_name));
    if numel(vals) == 1
        name = char(vals(1));
    else
        name = 'mixed';
    end
end
end

function mode = infer_selection_mode(selector)
if isfield(selector, 'selection_mode') && ~isempty(selector.selection_mode)
    mode = char(string(selector.selection_mode));
else
    mode = 'filter';
end
end
