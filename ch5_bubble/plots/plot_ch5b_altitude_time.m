function fig = plot_ch5b_altitude_time(traj_samples, opts)
%PLOT_CH5B_ALTITUDE_TIME Plot altitude-time curves for one or more trajectories.

if nargin < 2
    opts = struct();
end

opts = apply_defaults(opts, struct( ...
    'visible', 'on', ...
    'line_width', 1.8, ...
    'title_text', 'ch5_bubble altitude-time', ...
    'ylabel_text', 'Altitude (km)'));

traj_samples = normalize_samples(traj_samples);

fig = figure('Visible', opts.visible);
hold on;
grid on;

legend_entries = cell(1, numel(traj_samples));
for i = 1:numel(traj_samples)
    ts = traj_samples(i);
    plot(ts.traj.t_s(:), ts.traj.h_km(:), 'LineWidth', opts.line_width);
    legend_entries{i} = sprintf('%s (%s)', ts.sample_id, ts.family_id);
end

xlabel('Time (s)', 'Interpreter', 'none');
ylabel(opts.ylabel_text, 'Interpreter', 'none');
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
