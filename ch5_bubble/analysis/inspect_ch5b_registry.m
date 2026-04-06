function inspect_ch5b_registry(sample_id)
%INSPECT_CH5B_REGISTRY Inspect real registry and one propagated sample.

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

if nargin < 1 || isempty(sample_id)
    sample_id = registry.sample_ids{1};
end

traj_sample = resolve_trajectory_sample(registry, sample_id, cfg);
summary = summarize_trajectory_sample(traj_sample);
diag_out = diagnose_trajectory_timeline(traj_sample);
stage02_info = load_stage02_trajectory_family(cfg);

disp('=== inspect_ch5b_registry :: registry ===');
disp(registry);

disp('=== inspect_ch5b_registry :: summary ===');
disp(summary);

disp('=== inspect_ch5b_registry :: timeline diagnosis ===');
disp(diag_out);

disp('=== inspect_ch5b_registry :: stage02 diagnose summary ===');
disp(rmfield(stage02_info, 'records'));

if ~isempty(stage02_info.records)
    disp('=== inspect_ch5b_registry :: stage02 diagnose records ===');
    disp(stage02_info.records);
end
end
