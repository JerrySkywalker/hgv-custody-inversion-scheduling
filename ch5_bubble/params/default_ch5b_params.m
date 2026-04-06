function cfg = default_ch5b_params()
%DEFAULT_CH5B_PARAMS Default configuration for Chapter 5 bubble framework.
%
% B1 manual-recipe version:
%   manual recipe -> synthetic case -> Stage02 propagation kernel

cfg = struct();

% -------------------------------------------------------------------------
% identity
% -------------------------------------------------------------------------
cfg.framework = struct();
cfg.framework.name = 'ch5_bubble';
cfg.framework.version = 'phaseB1_manual_recipe';
cfg.framework.phase = 'B1';
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
cfg.output.phase_name = 'phaseB1_manual_recipe';
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
% trajectory source
% -------------------------------------------------------------------------
cfg.trajectory = struct();
cfg.trajectory.source_mode = 'manual_recipe';
cfg.trajectory.default_family_id = 'NOMINAL';
cfg.trajectory.default_sample_id = 'N01';
cfg.trajectory.enable_mc = false;
cfg.trajectory.mc_count = 0;

% -------------------------------------------------------------------------
% geo / time anchors
% -------------------------------------------------------------------------
cfg.geo = struct();
cfg.geo.enable_geodetic_anchor = true;
cfg.geo.lat0_deg = 30.0;
cfg.geo.lon0_deg = 110.0;
cfg.geo.h0_m = 0.0;

cfg.time = struct();
cfg.time.epoch_utc = datetime(2025, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');

% -------------------------------------------------------------------------
% stage01 compatibility namespace
% only to satisfy Stage02 propagation kernel interface
% -------------------------------------------------------------------------
cfg.stage01 = struct();
cfg.stage01.disk_center_xy_km = [0.0, 0.0];

% -------------------------------------------------------------------------
% stage02 bridge config
% enough to drive the real propagation kernel
% -------------------------------------------------------------------------
cfg.stage02 = struct();

cfg.stage02.t0_s = 0.0;
cfg.stage02.Ts_s = 1.0;
cfg.stage02.Tmax_s = 2000.0;

cfg.stage02.v0_mps = 5500.0;
cfg.stage02.h0_m = 80000.0;
cfg.stage02.theta0_deg = -5.0;
cfg.stage02.sigma0_deg = 0.0;

cfg.stage02.h_min_m = 0.0;
cfg.stage02.h_max_m = 120000.0;
cfg.stage02.v_min_mps = 500.0;
cfg.stage02.v_max_mps = 9000.0;

cfg.stage02.Re_m = 6378137.0;
cfg.stage02.phi_ref_deg = cfg.geo.lat0_deg;
cfg.stage02.lambda_ref_deg = cfg.geo.lon0_deg;

cfg.stage02.enable_task_capture_event = false;
cfg.stage02.capture_radius_km = 50.0;
cfg.stage02.enable_landing_event = true;

cfg.stage02.alpha_cmd_deg = 10.0;
cfg.stage02.bank_cmd_deg = 0.0;
cfg.stage02.alpha_nominal_deg = 10.0;
cfg.stage02.bank_nominal_deg = 0.0;
cfg.stage02.alpha_heading_deg = 10.0;
cfg.stage02.bank_heading_deg = 0.0;
cfg.stage02.alpha_c1_deg = 10.0;
cfg.stage02.bank_c1_deg = 0.0;
cfg.stage02.alpha_c2_deg = 10.0;
cfg.stage02.bank_c2_deg = 0.0;

cfg.stage02.use_heading_offset_as_bank_seed = false;
cfg.stage02.heading_offset_bank_gain_deg_per_deg = 0.0;

% -------------------------------------------------------------------------
% placeholders for later phases
% -------------------------------------------------------------------------
cfg.case_builder = struct();
cfg.case_builder.case_id = 'CH5B_CASE_DEMO';
cfg.case_builder.sensor_profile = 'baseline';
cfg.case_builder.constellation_tag = 'UNSET_IN_B1';

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

cfg.contract = struct();
cfg.contract.require_selection_trace_schema = true;
cfg.contract.require_metric_bundle_schema = true;
cfg.contract.require_case_artifact_schema = true;
cfg.contract.require_real_stage02_bridge = true;
cfg.contract.require_manual_recipe_mode = true;

end
