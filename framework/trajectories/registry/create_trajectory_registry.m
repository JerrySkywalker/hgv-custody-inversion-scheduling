function registry = create_trajectory_registry(registry_name)
%CREATE_TRAJECTORY_REGISTRY Create an empty trajectory registry.
%   registry = CREATE_TRAJECTORY_REGISTRY()
%   registry = CREATE_TRAJECTORY_REGISTRY(registry_name)

if nargin < 1 || isempty(registry_name)
    registry_name = "default_registry";
end

traj_id = strings(0,1);
class_name = strings(0,1);
bundle_id = strings(0,1);
source_kind = strings(0,1);
generator_id = strings(0,1);
base_traj_id = strings(0,1);
sample_id = zeros(0,1);
variation_kind = strings(0,1);
payload = cell(0,1);

items = table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);

registry = struct();
registry.registry_name = string(registry_name);
registry.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
registry.items = items;
registry.item_count = height(items);
end
