function items = make_trajectory_item_table(traj_id, family_name, group_name, source_kind, generator_id, payload)
%MAKE_TRAJECTORY_ITEM_TABLE Build standardized trajectory item table.
%
%   items = MAKE_TRAJECTORY_ITEM_TABLE(traj_id, family_name, group_name, ...
%       source_kind, generator_id, payload)

traj_id = string(traj_id(:));
family_name = string(family_name(:));
group_name = string(group_name(:));
source_kind = string(source_kind(:));
generator_id = string(generator_id(:));

if iscell(payload)
    payload = payload(:);
else
    payload = num2cell(payload(:));
end

n = numel(traj_id);

assert_same_length(family_name, n, 'family_name');
assert_same_length(group_name, n, 'group_name');
assert_same_length(source_kind, n, 'source_kind');
assert_same_length(generator_id, n, 'generator_id');
assert_same_length(payload, n, 'payload');

items = table(traj_id, family_name, group_name, source_kind, generator_id, payload);
end

function assert_same_length(x, n, name)
if numel(x) ~= n
    error('make_trajectory_item_table:LengthMismatch', ...
        'Input %s must have %d elements, but got %d.', name, n, numel(x));
end
end
