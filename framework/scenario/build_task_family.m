function task_family = build_task_family(registry, selector)
%BUILD_TASK_FAMILY Build a task set from a trajectory registry.
%
%   selector optional fields:
%     - class_name
%     - bundle_id
%     - source_kind
%     - generator_id
%     - traj_id
%     - base_traj_id
%     - variation_kind
%     - selection_mode
%
%   Supported selection_mode:
%     - all_enabled   : return all items in registry
%     - full          : if class_name empty, all items; otherwise all items of that class
%     - class_filter  : require class_name
%     - bundle_filter : require base_traj_id or bundle_id
%     - filter        : generic field-wise intersection filter (legacy-compatible)
%
%   Legacy-compatible aliases:
%     - family_name -> class_name
%     - group_name  -> bundle_id

if nargin < 2 || isempty(selector)
    selector = struct();
end

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('build_task_family:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

selector = normalize_selector(selector);
all_items = registry.items;

selection_mode = infer_selection_mode(selector);
items = all_items;

switch string(selection_mode)
    case "all_enabled"
        items = all_items;

    case "full"
        if isfield(selector, 'class_name') && ~isempty(selector.class_name)
            items = all_items(string(all_items.class_name) == string(selector.class_name), :);
        else
            items = all_items;
        end

    case "class_filter"
        if ~isfield(selector, 'class_name') || isempty(selector.class_name)
            error('build_task_family:MissingClassName', ...
                'class_name is required when selection_mode = class_filter.');
        end
        items = all_items(string(all_items.class_name) == string(selector.class_name), :);

    case "bundle_filter"
        if isfield(selector, 'bundle_id') && ~isempty(selector.bundle_id)
            items = all_items(string(all_items.bundle_id) == string(selector.bundle_id), :);
        elseif isfield(selector, 'base_traj_id') && ~isempty(selector.base_traj_id)
            bundle_id = string(selector.base_traj_id) + "_heading";
            items = all_items(string(all_items.bundle_id) == bundle_id, :);
        else
            error('build_task_family:MissingBundleSelector', ...
                'bundle_filter requires bundle_id or base_traj_id.');
        end

    case "filter"
        items = apply_generic_filters(all_items, selector);

    otherwise
        error('build_task_family:UnsupportedSelectionMode', ...
            'Unsupported selection_mode: %s', char(string(selection_mode)));
end

task_family = struct();
task_family.class_name = infer_class_name(items, selector);
task_family.source_registry_name = char(registry.registry_name);
task_family.selection_mode = char(string(selection_mode));
task_family.selector = selector;
task_family.items = items;
task_family.item_count = height(items);
task_family.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end

function selector = normalize_selector(selector)
if isfield(selector, 'family_name') && ~isfield(selector, 'class_name')
    selector.class_name = selector.family_name;
end
if isfield(selector, 'group_name') && ~isfield(selector, 'bundle_id')
    selector.bundle_id = selector.group_name;
end
end

function items = apply_generic_filters(items, selector)
if isfield(selector, 'class_name') && ~isempty(selector.class_name)
    items = items(string(items.class_name) == string(selector.class_name), :);
end

if isfield(selector, 'bundle_id') && ~isempty(selector.bundle_id)
    items = items(string(items.bundle_id) == string(selector.bundle_id), :);
end

if isfield(selector, 'source_kind') && ~isempty(selector.source_kind)
    items = items(string(items.source_kind) == string(selector.source_kind), :);
end

if isfield(selector, 'generator_id') && ~isempty(selector.generator_id)
    items = items(string(items.generator_id) == string(selector.generator_id), :);
end

if isfield(selector, 'base_traj_id') && ~isempty(selector.base_traj_id)
    items = items(string(items.base_traj_id) == string(selector.base_traj_id), :);
end

if isfield(selector, 'variation_kind') && ~isempty(selector.variation_kind)
    items = items(string(items.variation_kind) == string(selector.variation_kind), :);
end

if isfield(selector, 'traj_id') && ~isempty(selector.traj_id)
    wanted_ids = string(selector.traj_id(:));
    items = items(ismember(string(items.traj_id), wanted_ids), :);
end
end

function name = infer_class_name(items, selector)
if isfield(selector, 'class_name') && ~isempty(selector.class_name)
    name = char(string(selector.class_name));
elseif isempty(items)
    name = 'empty';
else
    vals = unique(string(items.class_name));
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
