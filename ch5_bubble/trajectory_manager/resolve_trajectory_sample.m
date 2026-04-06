function traj_sample = resolve_trajectory_sample(registry, sample_id, cfg)
%RESOLVE_TRAJECTORY_SAMPLE Resolve one trajectory sample from registry.
%
% Phase B1:
%   Return a schema-correct trajectory sample.
% Phase B1.2:
%   Add source-aware fallback logic.
%   Real legacy parsing is still deferred.

if nargin < 3
    cfg = default_ch5b_params();
end

idx = find(strcmp(registry.sample_ids, sample_id), 1, 'first');
if isempty(idx)
    error('resolve_trajectory_sample:SampleNotFound', ...
        'Sample id "%s" not found in registry.', sample_id);
end

meta = registry.samples(idx);

switch lower(meta.source_tag)
    case {'stub_nominal', 'stub_critical'}
        traj_sample = make_stub_sample(meta, cfg);
    otherwise
        traj_sample = make_stub_sample(meta, cfg);
        traj_sample.metadata.note = 'Real source parser not implemented yet; fallback to stub sample.';
end

end

function traj_sample = make_stub_sample(meta, cfg)

dt = 1.0;
n_steps = 201;
time = (0:n_steps-1)' * dt;

truth = zeros(n_steps, 6);
truth(:,1) = linspace(0, 200000, n_steps)';
truth(:,2) = linspace(0, 50000, n_steps)';
truth(:,3) = linspace(30000, 20000, n_steps)';
truth(:,4) = 1000;
truth(:,5) = 250;
truth(:,6) = -50;

% Slight differentiation for stub samples so labels are no longer numerically identical.
switch upper(meta.sample_id)
    case 'N02'
        truth(:,2) = truth(:,2) + 5000;
    case 'C01'
        truth(:,3) = truth(:,3) - 2000;
        truth(:,6) = -80;
end

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
traj_sample.metadata.phase = 'B1.2';
traj_sample.metadata.source_mode = cfg.trajectory.source_mode;

end
