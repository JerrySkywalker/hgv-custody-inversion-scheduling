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
addParameter(p, 'scene_mode', "local_disk", @(x) ischar(x) || isstring(x));
addParameter(p, 'anchor_lat_deg', NaN, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'anchor_lon_deg', NaN, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'anchor_h_m', NaN, @(x) isnumeric(x) && isscalar(x));

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
    entry_theta_deg = angles_deg(k);
    heading_deg = mod(entry_theta_deg + 180, 360);
    if heading_deg > 180
        heading_deg = heading_deg - 360;
    end

    traj_id(k) = sprintf('traj_%s_%03d', char(string(opts.class_name)), k);

    entry_point_xy_km = [x0_km(k), y0_km(k)];
    heading_unit_xy = [cosd(heading_deg), sind(heading_deg)];

    payload{k} = struct( ...
        'point_index', k, ...
        'angle_deg', angles_deg(k), ...
        'entry_theta_deg', entry_theta_deg, ...
        'heading_deg', heading_deg, ...
        'heading_offset_deg', 0, ...
        'x0_km', x0_km(k), ...
        'y0_km', y0_km(k), ...
        'entry_point_xy_km', entry_point_xy_km, ...
        'heading_unit_xy', heading_unit_xy, ...
        'entry_point_enu_km', entry_point_xy_km, ...
        'entry_point_enu_m', entry_point_xy_km * 1000, ...
        'heading_unit_enu', heading_unit_xy, ...
        'entry_radius_km', entry_radius_km, ...
        'center_xy_km', center_xy_km, ...
        'scene_mode', char(string(opts.scene_mode)), ...
        'anchor_lat_deg', double(opts.anchor_lat_deg), ...
        'anchor_lon_deg', double(opts.anchor_lon_deg), ...
        'anchor_h_m', double(opts.anchor_h_m));
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
