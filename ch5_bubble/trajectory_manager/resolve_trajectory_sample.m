function traj_sample = resolve_trajectory_sample(registry, sample_id, cfg)
%RESOLVE_TRAJECTORY_SAMPLE Resolve one trajectory sample from registry.
%
% Phase B1:
%   Return a schema-correct stub trajectory sample.
%   This function freezes the object contract before real data integration.

if nargin < 3
    cfg = default_ch5b_params();
end

idx = find(strcmp(registry.sample_ids, sample_id), 1, 'first');
if isempty(idx)
    error('resolve_trajectory_sample:SampleNotFound', ...
        'Sample id "%s" not found in registry.', sample_id);
end

meta = registry.samples(idx);

dt = 1.0;
n_steps = 201;
time = (0:n_steps-1)' * dt;

% Simple deterministic stub truth:
% columns: [x, y, z, vx, vy, vz]
truth = zeros(n_steps, 6);
truth(:,1) = linspace(0, 200000, n_steps)';
truth(:,2) = linspace(0, 50000, n_steps)';
truth(:,3) = linspace(30000, 20000, n_steps)';
truth(:,4) = 1000;
truth(:,5) = 250;
truth(:,6) = -50;

traj_sample = struct();
traj_sample.sample_id = meta.sample_id;
traj_sample.family_id = meta.family_id;
traj_sample.case_label = meta.case_label;
traj_sample.source_tag = meta.source_tag;
traj_sample.description = meta.description;
traj_sample.time = time;
traj_sample.truth = truth;
traj_sample.dt = dt;
traj_sample.n_steps = n_steps;
traj_sample.t_start = time(1);
traj_sample.t_end = time(end);
traj_sample.state_dim = size(truth, 2);
traj_sample.first_state = truth(1,:);
traj_sample.last_state = truth(end,:);
traj_sample.terminal_reason = 'stub_fixed_horizon';
traj_sample.metadata = struct();
traj_sample.metadata.framework = 'ch5_bubble';
traj_sample.metadata.phase = 'B1';
traj_sample.metadata.source_mode = cfg.trajectory.source_mode;

end
