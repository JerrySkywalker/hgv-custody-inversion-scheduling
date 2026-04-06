function fig = plot_ch5b_trajectory_3d(traj_sample, opts)
%PLOT_CH5B_TRAJECTORY_3D Plot one trajectory in Stage02-like 3D style.
%
% Default behavior for coord_frame = 'enu':
%   x = East (km)
%   y = North (km)
%   z = Altitude h_km
%
% This is intentionally different from directly plotting r_enu_km(:,3),
% because Stage02-style trajectory plots are more naturally interpreted as
% ground-track + altitude, not raw local-up coordinate.

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'coord_frame', 'enu', ...
    'z_mode', 'altitude', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 36, ...
    'title_prefix', 'ch5_bubble trajectory 3D', ...
    'view_az_deg', 45, ...
    'view_el_deg', 25, ...
    'z_exaggeration', 12.0));

[x, y, z, labels] = local_pick_xyz(traj_sample, opts.coord_frame, opts.z_mode);

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

% Stage02-like visual scaling:
% do not use axis equal, otherwise altitude gets flattened.
xr = max(x) - min(x); if xr <= 0, xr = 1; end
yr = max(y) - min(y); if yr <= 0, yr = 1; end
zr = max(z) - min(z); if zr <= 0, zr = 1; end

xy_scale = max([xr, yr]);
z_scale = zr / opts.z_exaggeration;
if z_scale <= 0
    z_scale = 1;
end

pbaspect([xr / xy_scale, yr / xy_scale, zr / z_scale]);
axis tight;

hold off;

end

function [x, y, z, labels] = local_pick_xyz(traj_sample, coord_frame, z_mode)
traj = traj_sample.traj;

switch lower(coord_frame)
    case 'enu'
        assert(isfield(traj, 'r_enu_km'), 'plot_ch5b_trajectory_3d:MissingENU', 'traj.r_enu_km missing.');
        x = traj.r_enu_km(:,1);
        y = traj.r_enu_km(:,2);

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

        labels.xlabel = 'enu-x / east (km)';
        labels.ylabel = 'enu-y / north (km)';

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

function s = apply_defaults(s, defaults)
fns = fieldnames(defaults);
for i = 1:numel(fns)
    if ~isfield(s, fns{i}) || isempty(s.(fns{i}))
        s.(fns{i}) = defaults.(fns{i});
    end
end
end
