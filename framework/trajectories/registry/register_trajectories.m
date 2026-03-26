function registry = register_trajectories(registry, new_items)
%REGISTER_TRAJECTORIES Register new trajectory tracks into registry.

if nargin < 2
    error('register_trajectories:NotEnoughInputs', ...
        'registry and new_items are required.');
end

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('register_trajectories:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

if ~istable(new_items)
    error('register_trajectories:InvalidItems', ...
        'new_items must be a table.');
end

required_vars = { ...
    'traj_id','class_name','bundle_id','source_kind','generator_id', ...
    'base_traj_id','sample_id','variation_kind','payload'};

for k = 1:numel(required_vars)
    if ~ismember(required_vars{k}, new_items.Properties.VariableNames)
        error('register_trajectories:MissingVariable', ...
            'new_items is missing required variable: %s', required_vars{k});
    end
end

new_items = normalize_item_table(new_items);

if ~isempty(registry.items)
    existing_ids = string(registry.items.traj_id);
else
    existing_ids = strings(0,1);
end

incoming_ids = string(new_items.traj_id);

if numel(unique(incoming_ids)) ~= numel(incoming_ids)
    error('register_trajectories:DuplicateIncomingIDs', ...
        'Duplicate traj_id detected inside new_items.');
end

if any(ismember(incoming_ids, existing_ids))
    error('register_trajectories:DuplicateRegistryIDs', ...
        'Incoming traj_id conflicts with existing registry traj_id.');
end

registry.items = [registry.items; new_items];
registry.item_count = height(registry.items);
end

function tbl = normalize_item_table(tbl)
tbl.traj_id = string(tbl.traj_id);
tbl.class_name = string(tbl.class_name);
tbl.bundle_id = string(tbl.bundle_id);
tbl.source_kind = string(tbl.source_kind);
tbl.generator_id = string(tbl.generator_id);
tbl.base_traj_id = string(tbl.base_traj_id);
tbl.variation_kind = string(tbl.variation_kind);
tbl.sample_id = double(tbl.sample_id);

if ~iscell(tbl.payload)
    tbl.payload = num2cell(tbl.payload);
end
end
