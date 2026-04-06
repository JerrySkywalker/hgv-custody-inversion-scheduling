function fig = plot_ch5b_trajectory_family_3d(traj_samples, opts)
%PLOT_CH5B_TRAJECTORY_FAMILY_3D Plot multiple trajectory samples in one 3D figure.
%
% Inputs
%   traj_samples : struct array or cell array of trajectory sample structs
%   opts         : plotting options

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'show_start_end', true, ...
    'line_width', 1.8, ...
    'marker_size', 28, ...
    'title_text', 'ch5\_bubble trajectory family 3D', ...
    'xlabel_text', 'x', ...
    'ylabel_text', 'y', ...
    'zlabel_text', 'z'));

traj_samples = normalize_samples(traj_samples);

fig = figure('Visible', opts.visible);
hold on;
grid on;
axis equal;

legend_entries = cell(1, numel(traj_samples));

for i = 1:numel(traj_samples)
    ts = traj_samples(i);
    truth = ts.truth;
    assert(size(truth,2) >= 3, 'plot_ch5b_trajectory_family_3d:InvalidTruth', ...
        'Trajectory truth must have at least 3 columns for 3D plotting.');

    plot3(truth(:,1), truth(:,2), truth(:,3), 'LineWidth', opts.line_width);

    if opts.show_start_end
        scatter3(truth(1,1), truth(1,2), truth(1,3), opts.marker_size, 'filled');
        scatter3(truth(end,1), truth(end,2), truth(end,3), opts.marker_size, 'filled');
    end

    legend_entries{i} = sprintf('%s (%s)', ts.sample_id, ts.family_id);
end

xlabel(opts.xlabel_text, 'Interpreter', 'none');
ylabel(opts.ylabel_text, 'Interpreter', 'none');
zlabel(opts.zlabel_text, 'Interpreter', 'none');
title(opts.title_text, 'Interpreter', 'none');
legend(legend_entries, 'Interpreter', 'none', 'Location', 'best');
hold off;

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
