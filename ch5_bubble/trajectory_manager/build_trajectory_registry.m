function registry = build_trajectory_registry(cfg)
%BUILD_TRAJECTORY_REGISTRY Build a lightweight trajectory registry for ch5_bubble.
%
% Phase B1:
%   Freeze registry schema first.
%   Real Stage02/cache integration will be added in later sub-steps.

if nargin < 1
    cfg = default_ch5b_params();
end

samples = struct([]);

samples(1).sample_id = 'N01';
samples(1).family_id = 'NOMINAL';
samples(1).case_label = 'nominal_primary';
samples(1).source_tag = 'stub_nominal';
samples(1).description = 'Phase B1 stub nominal sample 01';

samples(2).sample_id = 'N02';
samples(2).family_id = 'NOMINAL';
samples(2).case_label = 'nominal_secondary';
samples(2).source_tag = 'stub_nominal';
samples(2).description = 'Phase B1 stub nominal sample 02';

samples(3).sample_id = 'C01';
samples(3).family_id = 'CRITICAL';
samples(3).case_label = 'critical_demo';
samples(3).source_tag = 'stub_critical';
samples(3).description = 'Phase B1 stub critical sample 01';

registry = struct();
registry.framework = 'ch5_bubble';
registry.phase = 'B1';
registry.version = 'phaseB1_registry_stub';
registry.source_mode = cfg.trajectory.source_mode;
registry.sample_count = numel(samples);
registry.samples = samples;
registry.family_ids = unique({samples.family_id});
registry.sample_ids = {samples.sample_id};
registry.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

end
