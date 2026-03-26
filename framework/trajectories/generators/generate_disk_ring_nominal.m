function items = generate_disk_ring_nominal(num_points, entry_radius_km, varargin)
%GENERATE_DISK_RING_NOMINAL Generate nominal entry points on a disk ring.

p = inputParser;
addRequired(p, 'num_points', @(x) isnumeric(x) && isscalar(x) && (x >= 1));
addRequired(p, 'entry_radius_km', @(x) isnumeric(x) && isscalar(x) && (x > 0));

addParameter(p, 'class_name', "nominal", @(x) ischar(x) || isstring(x));
addParameter(p, 'bundle_id', "ring_nominal", @(x) ischar(x) || isstring(x));
addParameter(p, 'generator_id', "disk_ring_nominal", @(x) ischar(x) || isstring(x));
addParameter(p, 'center_xy_km', [0, 0], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'start_angle_deg', 0, @(x) isnumeric(x) && isscalar(x));

parse(p, num_points, entry_radius_km, varargin{:});
opts = p.Results;

num_points = double(opts.num_points);
entry_radius_km = double(opts.entry_radius_km);
center_xy_km = double(opts.center_xy_km(:)).';
start_angle_deg = double(opts.start_angle_deg);

angles_deg = start_angle_deg + (0:num_points-1)' * (360.0 / num_points);
angles_rad = deg2rad(angles_deg);

x0_km = center_xy_km(1) + entry_radius_km * cos(angles_rad);
y0_km = center_xy_km(2) + entry_radius_km * sin(angles_rad);

traj_id = strings(num_points, 1);
payload = cell(num_points, 1);

for k = 1:num_points
    traj_id(k) = sprintf('traj_%s_%03d', char(string(opts.class_name)), k);

    payload{k} = struct( ...
        'point_index', k, ...
        'angle_deg', angles_deg(k), ...
        'x0_km', x0_km(k), ...
        'y0_km', y0_km(k), ...
        'entry_radius_km', entry_radius_km, ...
        'center_xy_km', center_xy_km);
end

class_name = repmat(string(opts.class_name), num_points, 1);
bundle_id = repmat(string(opts.bundle_id), num_points, 1);
source_kind = repmat("generator", num_points, 1);
generator_id = repmat(string(opts.generator_id), num_points, 1);
base_traj_id = repmat("", num_points, 1);
sample_id = (1:num_points)';
variation_kind = repmat("", num_points, 1);

items = make_trajectory_item_table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);
end
