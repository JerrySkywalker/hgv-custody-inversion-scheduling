function fig = plot_ch5b_trajectory_3d(traj_sample, opts)
%PLOT_CH5B_TRAJECTORY_3D Plot one trajectory in Stage02-like 3D style.
%
% Default behavior for coord_frame = 'enu':
%   horizontal_mode = 'track_aligned'
%   x = along-track ground distance (km)
%   y = cross-track ground distance (km)
%   z = altitude h_km
%
% This is more suitable for Stage02-like visualization than raw east/north.

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'coord_frame', 'enu', ...
    'horizontal_mode', 'track_aligned', ...
    'z_mode', 'altitude', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 36, ...
    'title_prefix', 'ch5_bubble trajectory 3D', ...
    'view_az_deg', -37.5, ...
    'view_el_deg', 28, ...
    'z_exaggeration', 10.0));

[x, y, z, labels] = local_pick_xyz(traj_sample, opts.coord_frame, opts.horizontal_mode, opts.z_mode);

fig = figure('Visible', opts.visible);
plot3(x, y, z, 'LineWidth', opts.line_width);
hold on;
grid on;
box on;

if opts.show_start_end
    scatter3(x(1), y(1), z(1), opts.marker_size, 'filled');
    scatter3(x(end), y(end), z(end), opts.marker_size, 'filled');
    text(x(1), y(1), z(1), '  start', 'Interpreter', 'none');
    text(x(end), y(end), z(end), '  end', 'Interpreter', 'none');
end

xlabel(labels.xlabel, 'Interpreter', 'none');
ylabel(labels.ylabel, 'Interpreter', 'none');
zlabel(labels.zlabel, 'Interpreter', 'none');

title(sprintf('%s: %s (%s)', ...
    opts.title_prefix, traj_sample.sample_id, traj_sample.family_id), ...
    'Interpreter', 'none');

legend({traj_sample.sample_id}, 'Interpreter', 'none', 'Location', 'best');

view(opts.view_az_deg, opts.view_el_deg);

xr = max(x) - min(x); if xr <= 0, xr = 1; end
yr = max(y) - min(y); if yr <= 0, yr = 1; end
zr = max(z) - min(z); if zr <= 0, zr = 1; end

xy_scale = max([xr, yr]);
z_scale = max(zr / opts.z_exaggeration, 1e-6);

pbaspect([xr / xy_scale, yr / xy_scale, zr / z_scale]);
axis tight;

hold off;

end

function [x, y, z, labels] = local_pick_xyz(traj_sample, coord_frame, horizontal_mode, z_mode)
traj = traj_sample.traj;

switch lower(coord_frame)
    case 'enu'
        assert(isfield(traj, 'r_enu_km'), 'plot_ch5b_trajectory_3d:MissingENU', 'traj.r_enu_km missing.');
        east = traj.r_enu_km(:,1);
        north = traj.r_enu_km(:,2);

        switch lower(horizontal_mode)
            case 'raw_enu'
                x = east;
                y = north;
                labels.xlabel = 'enu-x / east (km)';
                labels.ylabel = 'enu-y / north (km)';

            case 'track_aligned'
                [x, y] = local_rotate_to_track_frame(east, north);
                labels.xlabel = 'along-track ground distance (km)';
                labels.ylabel = 'cross-track ground distance (km)';

            otherwise
                error('plot_ch5b_trajectory_3d:UnsupportedHorizontalMode', ...
                    'Unsupported horizontal_mode for ENU: %s', horizontal_mode);
        end

        switch lower(z_mode)
            case 'altitude'
                assert(isfield(traj, 'h_km'), 'plot_ch5b_trajectory_3d:MissingAltitude', 'traj.h_km missing.');
                z = traj.h_km(:);
                labels.zlabel = 'altitude (km)';
            case 'enu_z'
                z = traj.r_enu_km(:,3);
                labels.zlabel = 'enu-z (km)';
            otherwise
                error('plot_ch5b_trajectory_3d:UnsupportedZMode', ...
                    'Unsupported z_mode for ENU: %s', z_mode);
        end

    case 'eci'
        assert(isfield(traj, 'r_eci_km'), 'plot_ch5b_trajectory_3d:MissingECI', 'traj.r_eci_km missing.');
        x = traj.r_eci_km(:,1);
        y = traj.r_eci_km(:,2);
        z = traj.r_eci_km(:,3);
        labels.xlabel = 'eci-x (km)';
        labels.ylabel = 'eci-y (km)';
        labels.zlabel = 'eci-z (km)';

    case 'ecef'
        assert(isfield(traj, 'r_ecef_km'), 'plot_ch5b_trajectory_3d:MissingECEF', 'traj.r_ecef_km missing.');
        x = traj.r_ecef_km(:,1);
        y = traj.r_ecef_km(:,2);
        z = traj.r_ecef_km(:,3);
        labels.xlabel = 'ecef-x (km)';
        labels.ylabel = 'ecef-y (km)';
        labels.zlabel = 'ecef-z (km)';

    otherwise
        error('plot_ch5b_trajectory_3d:UnsupportedFrame', ...
            'Unsupported coord_frame: %s', coord_frame);
end
end

function [s, c] = local_rotate_to_track_frame(east, north)
east = east(:);
north = north(:);

de = east(end) - east(1);
dn = north(end) - north(1);

if hypot(de, dn) < 1e-9
    % fallback to PCA if start-end direction is degenerate
    X = [east - mean(east), north - mean(north)];
    [V, ~] = eig(X' * X);
    dir_vec = V(:,2);
else
    dir_vec = [de; dn] / hypot(de, dn);
end

cross_vec = [-dir_vec(2); dir_vec(1)];

origin = [east(1); north(1)];
pts = [east.'; north.'] - origin;

sc = [dir_vec.'; cross_vec.'] * pts;
s = sc(1,:).';
c = sc(2,:).';
end

function s = apply_defaults(s, defaults)
fns = fieldnames(defaults);
for i = 1:numel(fns)
    if ~isfield(s, fns{i}) || isempty(s.(fns{i}))
        s.(fns{i}) = defaults.(fns{i});
    end
end
end
