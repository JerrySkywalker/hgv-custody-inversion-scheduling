function fig = plot_single_trajectory_3d(traj, varargin)
%PLOT_SINGLE_TRAJECTORY_3D Plot one trajectory in 3D using framework outputs.
%
%   fig = PLOT_SINGLE_TRAJECTORY_3D(traj)
%
% Optional name-value:
%   'CoordinateMode' : 'enu_km' (default) | 'ecef_km'
%   'FigureVisible'  : 'on' (default) | 'off'
%   'OutputPath'     : save figure if non-empty

p = inputParser;
addRequired(p, 'traj', @isstruct);
addParameter(p, 'CoordinateMode', 'enu_km', @(x) ischar(x) || isstring(x));
addParameter(p, 'FigureVisible', 'on', @(x) ischar(x) || isstring(x));
addParameter(p, 'OutputPath', '', @(x) ischar(x) || isstring(x));
parse(p, traj, varargin{:});
opts = p.Results;

requested_mode = char(string(opts.CoordinateMode));
vis  = char(string(opts.FigureVisible));
outp = char(string(opts.OutputPath));

actual_mode = requested_mode;
[R, labels] = resolve_coords(traj, requested_mode);

if isempty(R)
    if strcmpi(requested_mode, 'enu_km')
        [R, labels] = resolve_coords(traj, 'ecef_km');
        actual_mode = 'ecef_km';
    end
end

if isempty(R)
    error('plot_single_trajectory_3d:NoValidCoordinates', ...
        'No valid coordinates available for plotting.');
end

if size(R,1) ~= 3 && size(R,2) == 3
    R = R.';
end
if size(R,1) ~= 3
    error('plot_single_trajectory_3d:InvalidShape', ...
        'Trajectory coordinates must be 3xN or Nx3.');
end

fig = figure('Visible', vis);
plot3(R(1,:), R(2,:), R(3,:), 'LineWidth', 1.5);
grid on;
axis equal;
xlabel(labels{1});
ylabel(labels{2});
zlabel(labels{3});

track_id = '';
if isfield(traj, 'track_id')
    track_id = char(string(traj.track_id));
end
title(sprintf('Trajectory 3D Plot (%s): %s', upper(actual_mode), track_id), 'Interpreter', 'none');

if ~isempty(outp)
    saveas(fig, outp);
end
end

function [R, labels] = resolve_coords(traj, mode)
R = [];
labels = {};

switch lower(mode)
    case 'enu_km'
        if isfield(traj, 'r_enu_km') && ~isempty(traj.r_enu_km) && ~any(isnan(traj.r_enu_km(:)))
            R = traj.r_enu_km;
            labels = {'E [km]', 'N [km]', 'U [km]'};
        end

    case 'ecef_km'
        if isfield(traj, 'r_ecef_km') && ~isempty(traj.r_ecef_km) && ~any(isnan(traj.r_ecef_km(:)))
            R = traj.r_ecef_km;
            labels = {'X [km]', 'Y [km]', 'Z [km]'};
        end

    otherwise
        error('plot_single_trajectory_3d:UnsupportedMode', ...
            'Unsupported CoordinateMode: %s', mode);
end
end
