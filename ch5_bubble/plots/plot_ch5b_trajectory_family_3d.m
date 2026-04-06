function fig = plot_ch5b_trajectory_family_3d(traj_samples, opts)
%PLOT_CH5B_TRAJECTORY_FAMILY_3D Plot multiple trajectories in Stage02-like 3D style.
%
% Default for ENU:
%   x = along-track
%   y = cross-track
%   z = altitude

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
    'marker_size', 28, ...
    'title_text', 'ch5_bubble trajectory family 3D', ...
    'view_az_deg', -37.5, ...
    'view_el_deg', 28, ...
    'z_exaggeration', 10.0));

traj_samples = normalize_samples(traj_samples);

fig = figure('Visible', opts.visible);
hold on;
grid on;
box on;

legend_entries = cell(1, numel(traj_samples));

all_x = [];
all_y = [];
all_z = [];

for i = 1:numel(traj_samples)
    ts = traj_samples(i);
    [x, y, z, labels] = local_pick_xyz(ts, opts.coord_frame, opts.horizontal_mode, opts.z_mode);

    plot3(x, y, z, 'LineWidth', opts.line_width);

    if opts.show_start_end
        scatter3(x(1), y(1), z(1), opts.marker_size, 'filled');
        scatter3(x(end), y(end), z(end), opts.marker_size, 'filled');
    end

    legend_entries{i} = sprintf('%s (%s)', ts.sample_id, ts.family_id);

    all_x = [all_x; x(:)]; %#ok<AGROW>
    all_y = [all_y; y(:)]; %#ok<AGROW>
    all_z = [all_z; z(:)]; %#ok<AGROW>
end

xlabel(labels.xlabel, 'Interpreter', 'none');
ylabel(labels.ylabel, 'Interpreter', 'none');
zlabel(labels.zlabel, 'Interpreter', 'none');
title(opts.title_text, 'Interpreter', 'none');
legend(legend_entries, 'Interpreter', 'none', 'Location', 'best');

view(opts.view_az_deg, opts.view_el_deg);

xr = max(all_x) - min(all_x); if xr <= 0, xr = 1; end
yr = max(all_y) - min(all_y); if yr <= 0, yr = 1; end
zr = max(all_z) - min(all_z); if zr <= 0, zr = 1; end

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
                error('Unsupported horizontal_mode for ENU: %s', horizontal_mode);
        end

        switch lower(z_mode)
            case 'altitude'
                z = traj.h_km(:);
                labels.zlabel = 'altitude (km)';
            case 'enu_z'
                z = traj.r_enu_km(:,3);
                labels.zlabel = 'enu-z (km)';
            otherwise
                error('Unsupported z_mode for ENU: %s', z_mode);
        end

    case 'eci'
        x = traj.r_eci_km(:,1);
        y = traj.r_eci_km(:,2);
        z = traj.r_eci_km(:,3);
        labels.xlabel = 'eci-x (km)';
        labels.ylabel = 'eci-y (km)';
        labels.zlabel = 'eci-z (km)';

    case 'ecef'
        x = traj.r_ecef_km(:,1);
        y = traj.r_ecef_km(:,2);
        z = traj.r_ecef_km(:,3);
        labels.xlabel = 'ecef-x (km)';
        labels.ylabel = 'ecef-y (km)';
        labels.zlabel = 'ecef-z (km)';

    otherwise
        error('Unsupported coord_frame: %s', coord_frame);
end
end

function [s, c] = local_rotate_to_track_frame(east, north)
east = east(:);
north = north(:);

de = east(end) - east(1);
dn = north(end) - north(1);

if hypot(de, dn) < 1e-9
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

function arr = normalize_samples(in)
if iscell(in)
    arr = [in{:}];
else
    arr = in;
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
