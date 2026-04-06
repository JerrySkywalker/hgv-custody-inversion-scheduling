function inspect_ch5b_registry(sample_id)
%INSPECT_CH5B_REGISTRY Inspect registry and one sample summary.

if nargin < 1
    sample_id = 'N01';
end

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);
traj_sample = resolve_trajectory_sample(registry, sample_id, cfg);
summary = summarize_trajectory_sample(traj_sample);
diag_out = diagnose_trajectory_timeline(traj_sample);

disp('=== inspect_ch5b_registry :: registry ===');
disp(registry);

disp('=== inspect_ch5b_registry :: summary ===');
disp(summary);

disp('=== inspect_ch5b_registry :: timeline diagnosis ===');
disp(diag_out);

end
