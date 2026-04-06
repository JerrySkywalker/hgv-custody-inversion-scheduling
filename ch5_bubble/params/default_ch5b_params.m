function cfg = default_ch5b_params()
%DEFAULT_CH5B_PARAMS Default configuration for Chapter 5 bubble framework.
%
% Phase B0:
%   Freeze the engineering skeleton and conventions only.
%   No heavy algorithm logic should be introduced here.

cfg = struct();

% -------------------------------------------------------------------------
% identity
% -------------------------------------------------------------------------
cfg.framework = struct();
cfg.framework.name = 'ch5_bubble';
cfg.framework.version = 'phaseB0';
cfg.framework.phase = 'B0';
cfg.framework.freeze_old_chain = true;
cfg.framework.legacy_reference = 'ch5_rebuild';

% -------------------------------------------------------------------------
% path / output
% -------------------------------------------------------------------------
cfg.path = struct();
cfg.path.root_dir = pwd;
cfg.path.module_dir = fullfile(cfg.path.root_dir, 'ch5_bubble');
cfg.path.output_root = fullfile(cfg.path.root_dir, 'outputs', 'ch5_bubble');

cfg.output = struct();
cfg.output.enable_save = true;
cfg.output.phase_name = 'phaseB0_smoke';
cfg.output.phase_dir = fullfile(cfg.path.output_root, cfg.output.phase_name);
cfg.output.logs_dir = fullfile(cfg.output.phase_dir, 'logs');
cfg.output.tables_dir = fullfile(cfg.output.phase_dir, 'tables');
cfg.output.figs_dir = fullfile(cfg.output.phase_dir, 'figs');
cfg.output.mats_dir = fullfile(cfg.output.phase_dir, 'mats');

% -------------------------------------------------------------------------
% development switches
% -------------------------------------------------------------------------
cfg.dev = struct();
cfg.dev.verbose = true;
cfg.dev.strict_mode = true;
cfg.dev.allow_legacy_cache_read = false;
cfg.dev.allow_plot_compute = false;
cfg.dev.require_registry_dispatch = true;

% -------------------------------------------------------------------------
% trajectory / case placeholders
% -------------------------------------------------------------------------
cfg.trajectory = struct();
cfg.trajectory.source_mode = 'stage02_or_resample';
cfg.trajectory.default_family_id = 'NOMINAL';
cfg.trajectory.default_sample_id = 'N01';
cfg.trajectory.enable_mc = false;
cfg.trajectory.mc_count = 0;

cfg.case_builder = struct();
cfg.case_builder.case_id = 'CH5B_CASE_DEMO';
cfg.case_builder.sensor_profile = 'baseline';
cfg.case_builder.constellation_tag = 'UNSET_IN_B0';

% -------------------------------------------------------------------------
% policy / metrics placeholders
% -------------------------------------------------------------------------
cfg.policy = struct();
cfg.policy.default_policy_name = 'static_hold';
cfg.policy.registry_mode = 'builtin_only';

cfg.metrics = struct();
cfg.metrics.primary_window_mode = 'forward_full_only';
cfg.metrics.enable_bubble = true;
cfg.metrics.enable_lambda = true;
cfg.metrics.enable_rmse = true;
cfg.metrics.enable_requirement = true;
cfg.metrics.enable_cost = true;

% -------------------------------------------------------------------------
% B0 contract
% -------------------------------------------------------------------------
cfg.contract = struct();
cfg.contract.require_selection_trace_schema = true;
cfg.contract.require_metric_bundle_schema = true;
cfg.contract.require_case_artifact_schema = true;

end
