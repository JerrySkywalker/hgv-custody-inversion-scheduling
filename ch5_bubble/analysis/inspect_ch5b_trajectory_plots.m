function inspect_ch5b_trajectory_plots(sample_ids)
%INSPECT_CH5B_TRAJECTORY_PLOTS Manual inspection using real propagated trajectories.

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

if nargin < 1 || isempty(sample_ids)
    preferred = {'N01', 'N02', 'C1_track_plane_aligned'};
    sample_ids = local_pick_existing_ids(preferred, registry.sample_ids);
    if isempty(sample_ids)
        sample_ids = registry.sample_ids(1:min(3, numel(registry.sample_ids)));
    end
end

traj_samples = cell(1, numel(sample_ids));
for i = 1:numel(sample_ids)
    traj_samples{i} = resolve_trajectory_sample(registry, sample_ids{i}, cfg);
end

for i = 1:numel(traj_samples)
    plot_ch5b_trajectory_3d(traj_samples{i}, struct('visible', 'on', 'coord_frame', 'enu'));
end

plot_ch5b_trajectory_family_3d(traj_samples, struct( ...
    'visible', 'on', ...
    'coord_frame', 'enu', ...
    'title_text', 'Manual inspection: Phase B1 trajectory family 3D'));

plot_ch5b_altitude_time(traj_samples, struct( ...
    'visible', 'on', ...
    'title_text', 'Manual inspection: Altitude-Time'));

plot_ch5b_speed_time(traj_samples, struct( ...
    'visible', 'on', ...
    'title_text', 'Manual inspection: Speed-Time'));

end

function picked = local_pick_existing_ids(preferred, available)
picked = {};
for i = 1:numel(preferred)
    if any(strcmp(available, preferred{i}))
        picked{end+1} = preferred{i}; %#ok<AGROW>
    end
end
end
