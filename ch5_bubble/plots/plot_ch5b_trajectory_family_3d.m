function fig = plot_ch5b_trajectory_family_3d(traj_samples, opts)
%PLOT_CH5B_TRAJECTORY_FAMILY_3D Plot multiple trajectories in Stage02-like 3D style.
%
% Default behavior for coord_frame = 'enu':
%   x = East (km)
%   y = North (km)
%   z = Altitude h_km

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'coord_frame', 'enu', ...
    'z_mode', 'altitude', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 28, ...
    'title_text', 'ch5_bubble trajectory family 3D', ...
    'view_az_deg', 45, ...
    'view_el_deg', 25, ...
    'z_exaggeration', 12.0));

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
    [x, y, z, labels] = local_pick_xyz(ts, opts.coord_frame, opts.z_mode);

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
        x = traj.r_enu_km(:,1);
        y = traj.r_enu_km(:,2);

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

        labels.xlabel = 'enu-x / east (km)';
        labels.ylabel = 'enu-y / north (km)';

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
