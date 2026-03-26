function items = generate_heading_offset_family(base_items, heading_offsets_deg, varargin)
%GENERATE_HEADING_OFFSET_FAMILY Generate heading-offset bundle from base tracks.

p = inputParser;
addRequired(p, 'base_items', @istable);
addRequired(p, 'heading_offsets_deg', @(x) isnumeric(x) && ~isempty(x));

addParameter(p, 'class_name', "heading", @(x) ischar(x) || isstring(x));
addParameter(p, 'generator_id', "heading_offset_family", @(x) ischar(x) || isstring(x));
addParameter(p, 'variation_kind', "heading_offset", @(x) ischar(x) || isstring(x));

parse(p, base_items, heading_offsets_deg, varargin{:});
opts = p.Results;

required_vars = { ...
    'traj_id','class_name','bundle_id','source_kind','generator_id', ...
    'base_traj_id','sample_id','variation_kind','payload'};

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
class_name = repmat(string(opts.class_name), n_total, 1);
bundle_id = strings(n_total,1);
source_kind = repmat("generator", n_total, 1);
generator_id = repmat(string(opts.generator_id), n_total, 1);
base_traj_id = strings(n_total,1);
sample_id = zeros(n_total,1);
variation_kind = repmat(string(opts.variation_kind), n_total, 1);
payload = cell(n_total,1);

row = 0;
for i = 1:n_base
    base_id = string(base_items.traj_id(i));
    base_payload = base_items.payload{i};
    this_bundle_id = base_id + "_heading";

    if isfield(base_payload, 'entry_theta_deg')
        entry_theta_deg = double(base_payload.entry_theta_deg);
    else
        entry_theta_deg = NaN;
    end

    if isfield(base_payload, 'heading_deg')
        base_heading_deg = double(base_payload.heading_deg);
    else
        base_heading_deg = NaN;
    end

    if isfield(base_payload, 'entry_point_xy_km')
        entry_point_xy_km = double(base_payload.entry_point_xy_km);
    else
        entry_point_xy_km = [NaN, NaN];
    end

    for j = 1:n_offsets
        row = row + 1;
        offset = double(heading_offsets_deg(j));
        heading_deg = base_heading_deg + offset;

        traj_id(row) = sprintf('%s_h%+03d', char(base_id), round(offset));
        bundle_id(row) = this_bundle_id;
        base_traj_id(row) = base_id;
        sample_id(row) = j;

        new_payload = base_payload;
        new_payload.base_traj_id = char(base_id);
        new_payload.bundle_id = char(this_bundle_id);
        new_payload.entry_theta_deg = entry_theta_deg;
        new_payload.base_heading_deg = base_heading_deg;
        new_payload.heading_deg = heading_deg;
        new_payload.heading_offset_deg = offset;
        new_payload.entry_point_xy_km = entry_point_xy_km;
        new_payload.heading_unit_xy = [cosd(heading_deg), sind(heading_deg)];

        payload{row} = new_payload;
    end
end

items = make_trajectory_item_table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);
end
