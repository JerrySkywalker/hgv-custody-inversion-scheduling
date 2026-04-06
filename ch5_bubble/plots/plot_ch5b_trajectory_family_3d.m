function fig = plot_ch5b_trajectory_family_3d(traj_samples, opts)
%PLOT_CH5B_TRAJECTORY_FAMILY_3D Plot multiple real trajectories in 3D.

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'coord_frame', 'enu', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 28, ...
    'title_text', 'ch5_bubble real trajectory family 3D'));

traj_samples = normalize_samples(traj_samples);

fig = figure('Visible', opts.visible);
hold on;
grid on;
axis equal;

legend_entries = cell(1, numel(traj_samples));

for i = 1:numel(traj_samples)
    ts = traj_samples(i);
    xyz = local_pick_xyz(ts, opts.coord_frame);

    plot3(xyz(:,1), xyz(:,2), xyz(:,3), 'LineWidth', opts.line_width);

    if opts.show_start_end
        scatter3(xyz(1,1), xyz(1,2), xyz(1,3), opts.marker_size, 'filled');
        scatter3(xyz(end,1), xyz(end,2), xyz(end,3), opts.marker_size, 'filled');
    end

    legend_entries{i} = sprintf('%s (%s)', ts.sample_id, ts.family_id);
end

xlabel(sprintf('%s-x (km)', lower(opts.coord_frame)), 'Interpreter', 'none');
ylabel(sprintf('%s-y (km)', lower(opts.coord_frame)), 'Interpreter', 'none');
zlabel(sprintf('%s-z (km)', lower(opts.coord_frame)), 'Interpreter', 'none');
title(sprintf('%s [%s]', opts.title_text, upper(opts.coord_frame)), 'Interpreter', 'none');
legend(legend_entries, 'Interpreter', 'none', 'Location', 'best');
hold off;

end

function xyz = local_pick_xyz(traj_sample, coord_frame)
traj = traj_sample.traj;
switch lower(coord_frame)
    case 'enu'
        xyz = traj.r_enu_km;
    case 'eci'
        xyz = traj.r_eci_km;
    case 'ecef'
        xyz = traj.r_ecef_km;
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
