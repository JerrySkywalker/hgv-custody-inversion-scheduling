function fig = plot_ch5b_trajectory_3d(traj_sample, opts)
%PLOT_CH5B_TRAJECTORY_3D Plot one trajectory sample in 3D.
%
% Inputs
%   traj_sample : trajectory sample struct
%   opts        : plotting options
%
% Notes
%   Phase B1 plotting layer:
%   - plot only
%   - no trajectory computation here

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 36, ...
    'title_prefix', 'ch5\_bubble trajectory 3D', ...
    'xlabel_text', 'x', ...
    'ylabel_text', 'y', ...
    'zlabel_text', 'z'));

truth = traj_sample.truth;
assert(size(truth,2) >= 3, 'plot_ch5b_trajectory_3d:InvalidTruth', ...
    'Trajectory truth must have at least 3 columns for 3D plotting.');

fig = figure('Visible', opts.visible);
plot3(truth(:,1), truth(:,2), truth(:,3), 'LineWidth', opts.line_width);
grid on;
axis equal;
hold on;

if opts.show_start_end
    scatter3(truth(1,1), truth(1,2), truth(1,3), opts.marker_size, 'filled');
    scatter3(truth(end,1), truth(end,2), truth(end,3), opts.marker_size, 'filled');
    text(truth(1,1), truth(1,2), truth(1,3), '  start', 'Interpreter', 'none');
    text(truth(end,1), truth(end,2), truth(end,3), '  end', 'Interpreter', 'none');
end

xlabel(opts.xlabel_text, 'Interpreter', 'none');
ylabel(opts.ylabel_text, 'Interpreter', 'none');
zlabel(opts.zlabel_text, 'Interpreter', 'none');

title(sprintf('%s: %s (%s)', ...
    opts.title_prefix, traj_sample.sample_id, traj_sample.family_id), ...
    'Interpreter', 'none');

legend({traj_sample.sample_id}, 'Interpreter', 'none', 'Location', 'best');
hold off;

end

function s = apply_defaults(s, defaults)
fns = fieldnames(defaults);
for i = 1:numel(fns)
    if ~isfield(s, fns{i}) || isempty(s.(fns{i}))
        s.(fns{i}) = defaults.(fns{i});
    end
end
end
