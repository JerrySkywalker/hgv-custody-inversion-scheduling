function items = make_trajectory_item_table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload)
%MAKE_TRAJECTORY_ITEM_TABLE Build standardized trajectory track table.
%
%   items = MAKE_TRAJECTORY_ITEM_TABLE(...)
%
%   Standard columns:
%     - traj_id
%     - class_name
%     - bundle_id
%     - source_kind
%     - generator_id
%     - base_traj_id
%     - sample_id
%     - variation_kind
%     - payload

traj_id = string(traj_id(:));
class_name = string(class_name(:));
bundle_id = string(bundle_id(:));
source_kind = string(source_kind(:));
generator_id = string(generator_id(:));
base_traj_id = string(base_traj_id(:));
variation_kind = string(variation_kind(:));
sample_id = sample_id(:);

if iscell(payload)
    payload = payload(:);
else
    payload = num2cell(payload(:));
end

n = numel(traj_id);

assert_same_length(class_name, n, 'class_name');
assert_same_length(bundle_id, n, 'bundle_id');
assert_same_length(source_kind, n, 'source_kind');
assert_same_length(generator_id, n, 'generator_id');
assert_same_length(base_traj_id, n, 'base_traj_id');
assert_same_length(sample_id, n, 'sample_id');
assert_same_length(variation_kind, n, 'variation_kind');
assert_same_length(payload, n, 'payload');

items = table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);
end

function assert_same_length(x, n, name)
if numel(x) ~= n
    error('make_trajectory_item_table:LengthMismatch', ...
        'Input %s must have %d elements, but got %d.', name, n, numel(x));
end
end
