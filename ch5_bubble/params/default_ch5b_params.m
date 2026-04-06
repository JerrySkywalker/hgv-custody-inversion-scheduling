function cfg = default_ch5b_params()
%DEFAULT_CH5B_PARAMS Default configuration for Chapter 5 bubble framework.
%
% Current version:
%   - B0 engineering skeleton
%   - B1 real trajectory manager bridge to Stage01/Stage02
%   - provide Stage02-compatible config fields required by propagation

cfg = struct();

% -------------------------------------------------------------------------
% identity
% -------------------------------------------------------------------------
cfg.framework = struct();
cfg.framework.name = 'ch5_bubble';
cfg.framework.version = 'phaseB1_real';
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
cfg.output.phase_name = 'phaseB1_smoke';
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
cfg.dev.allow_legacy_cache_read = true;
cfg.dev.allow_plot_compute = false;
cfg.dev.require_registry_dispatch = true;

% -------------------------------------------------------------------------
% trajectory / case placeholders
% -------------------------------------------------------------------------
cfg.trajectory = struct();
cfg.trajectory.source_mode = 'stage01_casebank_plus_stage02_propagation';
cfg.trajectory.default_family_id = 'NOMINAL';
cfg.trajectory.default_sample_id = 'N01';
cfg.trajectory.enable_mc = false;
cfg.trajectory.mc_count = 0;

cfg.case_builder = struct();
cfg.case_builder.case_id = 'CH5B_CASE_DEMO';
cfg.case_builder.sensor_profile = 'baseline';
cfg.case_builder.constellation_tag = 'UNSET_IN_B1';

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
% Stage02 bridge config
% -------------------------------------------------------------------------
% These fields are added to satisfy the real propagation chain:
% Stage01 case -> build_hgv_cfg_from_case_stage02 -> propagate_hgv_case_stage02
%
% Values here are bridge defaults only. Specific case-dependent values
% should still be overridden inside build_hgv_cfg_from_case_stage02.

cfg.stage02 = struct();

% initial / nominal guidance-related defaults
cfg.stage02.v0_mps = 5500;
cfg.stage02.h0_m = 80000;
cfg.stage02.gamma0_deg = -5;
cfg.stage02.psi0_deg = 90;
cfg.stage02.sigma0_deg = 0;
cfg.stage02.alpha_cmd_deg = 10;
cfg.stage02.bank_cmd_deg = 0;

% propagation horizon and event bounds
cfg.stage02.Tmax_s = 2000;
cfg.stage02.h_min_m = 0;
cfg.stage02.h_max_m = 120000;
cfg.stage02.v_min_mps = 500;
cfg.stage02.v_max_mps = 9000;

% solver / sampling defaults
cfg.stage02.dt_eval_s = 1.0;
cfg.stage02.ode_solver = 'ode45';
cfg.stage02.rel_tol = 1e-8;
cfg.stage02.abs_tol = 1e-9;
cfg.stage02.max_step_s = 1.0;

% aerodynamic / vehicle placeholders
cfg.stage02.mass_kg = 1000;
cfg.stage02.Sref_m2 = 1.0;
cfg.stage02.CL0 = 0.0;
cfg.stage02.CD0 = 0.2;
cfg.stage02.k_induced = 0.05;

% earth / frame defaults
cfg.stage02.Re_m = 6378137.0;
cfg.stage02.mu_m3ps2 = 3.986004418e14;
cfg.stage02.omega_earth_radps = 7.2921150e-5;

% compatibility aliases that some legacy Stage02 functions may expect
cfg.stage02.h0_km = cfg.stage02.h0_m / 1000.0;
cfg.stage02.v0_kmps = cfg.stage02.v0_mps / 1000.0;
cfg.stage02.h_min_km = cfg.stage02.h_min_m / 1000.0;
cfg.stage02.h_max_km = cfg.stage02.h_max_m / 1000.0;

% -------------------------------------------------------------------------
% B1 contract
% -------------------------------------------------------------------------
cfg.contract = struct();
cfg.contract.require_selection_trace_schema = true;
cfg.contract.require_metric_bundle_schema = true;
cfg.contract.require_case_artifact_schema = true;
cfg.contract.require_real_stage02_bridge = true;

end
