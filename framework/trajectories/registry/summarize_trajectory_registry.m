function summary = summarize_trajectory_registry(registry)
%SUMMARIZE_TRAJECTORY_REGISTRY Build a lightweight summary for registry.

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('summarize_trajectory_registry:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

items = registry.items;

summary = struct();
summary.registry_name = char(registry.registry_name);
summary.created_at = registry.created_at;
summary.item_count = height(items);

if isempty(items)
    summary.class_names = strings(0,1);
    summary.bundle_ids = strings(0,1);
    summary.source_kinds = strings(0,1);
    summary.generator_ids = strings(0,1);
    summary.variation_kinds = strings(0,1);
else
    summary.class_names = unique(string(items.class_name));
    summary.bundle_ids = unique(string(items.bundle_id));
    summary.source_kinds = unique(string(items.source_kind));
    summary.generator_ids = unique(string(items.generator_id));
    summary.variation_kinds = unique(string(items.variation_kind));
end
end
