function items = generate_heading_offset_family(base_items, heading_offsets_deg, varargin)
%GENERATE_HEADING_OFFSET_FAMILY Generate heading-offset family from base items.
%
%   items = GENERATE_HEADING_OFFSET_FAMILY(base_items, heading_offsets_deg)
%
%   base_items must be a standardized trajectory item table.
%   Output is also a standardized trajectory item table suitable for direct
%   registration into the trajectory registry.

p = inputParser;
addRequired(p, 'base_items', @istable);
addRequired(p, 'heading_offsets_deg', @(x) isnumeric(x) && ~isempty(x));

addParameter(p, 'family_name', "heading", @(x) ischar(x) || isstring(x));
addParameter(p, 'group_name', "heading_offsets", @(x) ischar(x) || isstring(x));
addParameter(p, 'generator_id', "heading_offset_family", @(x) ischar(x) || isstring(x));

parse(p, base_items, heading_offsets_deg, varargin{:});
opts = p.Results;

required_vars = {'traj_id','family_name','group_name','source_kind','generator_id','payload'};
for k = 1:numel(required_vars)
    if ~ismember(required_vars{k}, base_items.Properties.VariableNames)
        error('generate_heading_offset_family:MissingVariable', ...
            'base_items is missing required variable: %s', required_vars{k});
    end
end

heading_offsets_deg = heading_offsets_deg(:);
n_base = height(base_items);
n_offsets = numel(heading_offsets_deg);
n_total = n_base * n_offsets;

traj_id = strings(n_total,1);
family_name = repmat(string(opts.family_name), n_total, 1);
group_name = repmat(string(opts.group_name), n_total, 1);
source_kind = repmat("generator", n_total, 1);
generator_id = repmat(string(opts.generator_id), n_total, 1);
payload = cell(n_total,1);

row = 0;
for i = 1:n_base
    base_id = string(base_items.traj_id(i));
    base_payload = base_items.payload{i};

    for j = 1:n_offsets
        row = row + 1;
        offset = heading_offsets_deg(j);

        traj_id(row) = sprintf('%s_h%+03d', char(base_id), round(offset));

        new_payload = base_payload;
        new_payload.base_traj_id = char(base_id);
        new_payload.heading_offset_deg = offset;

        payload{row} = new_payload;
    end
end

items = make_trajectory_item_table( ...
    traj_id, family_name, group_name, source_kind, generator_id, payload);
end
