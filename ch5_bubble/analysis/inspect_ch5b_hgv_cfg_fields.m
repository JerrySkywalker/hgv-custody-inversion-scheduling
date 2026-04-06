function inspect_ch5b_hgv_cfg_fields(sample_id)
%INSPECT_CH5B_HGV_CFG_FIELDS Show all hgv_cfg fields for one sample.

if nargin < 1 || isempty(sample_id)
    sample_id = 'N01';
end

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);
traj_sample = resolve_trajectory_sample(registry, sample_id, cfg);

disp('=== inspect_ch5b_hgv_cfg_fields :: fieldnames ===');
disp(fieldnames(traj_sample.hgv_cfg));

disp('=== inspect_ch5b_hgv_cfg_fields :: hgv_cfg ===');
disp(traj_sample.hgv_cfg);

end
