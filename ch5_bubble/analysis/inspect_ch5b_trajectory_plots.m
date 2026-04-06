function inspect_ch5b_trajectory_plots()
%INSPECT_CH5B_TRAJECTORY_PLOTS Manual inspection entry for Phase B1 3D plots.

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

traj_N01 = resolve_trajectory_sample(registry, 'N01', cfg);
traj_N02 = resolve_trajectory_sample(registry, 'N02', cfg);
traj_C01 = resolve_trajectory_sample(registry, 'C01', cfg);

plot_ch5b_trajectory_3d(traj_N01, struct('visible', 'on'));
plot_ch5b_trajectory_3d(traj_N02, struct('visible', 'on'));
plot_ch5b_trajectory_3d(traj_C01, struct('visible', 'on'));

plot_ch5b_trajectory_family_3d([traj_N01, traj_N02, traj_C01], struct( ...
    'visible', 'on', ...
    'title_text', 'Manual inspection: Phase B1 trajectory family 3D'));

end
