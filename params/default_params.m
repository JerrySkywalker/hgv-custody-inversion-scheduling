function cfg = default_params()
%DEFAULT_PARAMS Default configuration for the fresh-start Chapter 4 project.

    cfg = struct();

    % ---------------------------
    % Project metadata
    % ---------------------------
    cfg.project_name   = 'cpt4_disk_fresh';
    cfg.project_stage  = 'stage00';
    cfg.timestamp      = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    % ---------------------------
    % Paths
    % ---------------------------
    root_dir = fileparts(fileparts(mfilename('fullpath'))); % params -> root
    cfg.paths = struct();
    cfg.paths.root = root_dir;
    cfg.paths.outputs = fullfile(root_dir, 'outputs');
    cfg.paths.stage_outputs = fullfile(cfg.paths.outputs, 'stage');
    cfg.paths.benchmark_outputs = fullfile(cfg.paths.outputs, 'benchmark');
    cfg.paths.log_outputs = fullfile(cfg.paths.outputs, 'logs');
    cfg.paths.bundle_outputs = fullfile(cfg.paths.outputs, 'bundles');
    cfg.paths.milestone_outputs = fullfile(cfg.paths.outputs, 'milestones');
    cfg.paths.shared_scenario_outputs = fullfile(cfg.paths.outputs, 'shared_scenarios');
    cfg.paths.stage13_outputs = fullfile(cfg.paths.outputs, 'stage', 'stage13');

    % Deprecated compatibility fields. Keep these mapped to the unified
    % outputs/ layout while stage code is still being migrated.
    cfg.paths.output = cfg.paths.outputs;
    cfg.paths.results = cfg.paths.stage_outputs;
    cfg.paths.cache = fullfile(cfg.paths.stage_outputs, 'stage00', 'cache');
    cfg.paths.logs = fullfile(cfg.paths.log_outputs, 'stage00');
    cfg.paths.figs = fullfile(cfg.paths.stage_outputs, 'stage00', 'figs');
    cfg.paths.tables = fullfile(cfg.paths.stage_outputs, 'stage00', 'tables');
    cfg.paths.bundles = cfg.paths.bundle_outputs;
    cfg.paths.benchmarks = cfg.paths.benchmark_outputs;
    cfg.paths.milestones = cfg.paths.milestone_outputs;
    cfg.paths.shared_scenarios = cfg.paths.shared_scenario_outputs;
    cfg.paths.stage13 = cfg.paths.stage13_outputs;
    cfg = configure_stage_output_paths(cfg, cfg.project_stage);

    % ---------------------------
    % Benchmark controls
    % ---------------------------
    cfg.benchmark = struct();
    cfg.benchmark.enabled = true;
    cfg.benchmark.warmup_runs = 0;
    cfg.benchmark.enable_kernel_prewarm = true;
    cfg.benchmark.repeat = 1;
    cfg.benchmark.save_json = true;
    cfg.benchmark.save_mat = true;
    cfg.benchmark.default_abs_tol = 1e-12;
    cfg.benchmark.default_rel_tol = 1e-9;
    cfg.benchmark.default_ignored_fields = { ...
        'timestamp', 'log_file', 'cache_file', 'fig_file', 'fig3d_file', 'benchmark'};
    cfg.benchmark.primary_timing_view = 'cold';

    % Stage-level benchmark policy
    cfg.benchmark.stage01_disable_plot = true;
    cfg.benchmark.stage02_disable_plot = true;
    cfg.benchmark.stage02_repeat = 3;
    cfg.benchmark.stage02_disable_case_logging = true;
    cfg.benchmark.stage03_disable_plot = true;
    cfg.benchmark.stage03_repeat = 3;
    cfg.benchmark.stage03_disable_case_logging = true;
    cfg.benchmark.stage04_disable_plot = true;
    cfg.benchmark.stage04_repeat = 3;
    cfg.benchmark.stage04_disable_case_logging = true;
    cfg.benchmark.stage05_repeat = 3;
    cfg.benchmark.stage05_i_grid_deg = [40 60 80];
    cfg.benchmark.stage05_P_grid = [4 8];
    cfg.benchmark.stage05_T_grid = [4 8 12];
    cfg.benchmark.stage06_repeat = 3;
    cfg.benchmark.stage06_i_grid_deg = [40 60 80];
    cfg.benchmark.stage06_P_grid = [4 8];
    cfg.benchmark.stage06_T_grid = [4 8 12];
    cfg.benchmark.stage06_heading_offsets_deg = [0 -30 30];
    cfg.benchmark.stage07_repeat = 3;
    cfg.benchmark.stage07_entry_count = 4;
    cfg.benchmark.stage07_heading_step_deg = 15;
    cfg.benchmark.stage07_heading_max_abs_offset_deg = 45;
    cfg.benchmark.stage08_repeat = 3;
    cfg.benchmark.stage08_smallgrid_max_config_count = 6;
    cfg.benchmark.stage08_smallgrid_max_tw_count = 3;
    cfg.benchmark.stage08c_repeat = 3;
    cfg.benchmark.stage08c_h_km_list = 1000;
    cfg.benchmark.stage08c_i_deg_list = [50, 60];
    cfg.benchmark.stage08c_PT_pairs = [8, 4; 10, 4; 12, 4];
    cfg.benchmark.stage08c_max_tw_count = 3;
    cfg.benchmark.stage09_repeat = 3;
    cfg.benchmark.stage09_h_grid_km = [800, 1000];
    cfg.benchmark.stage09_i_grid_deg = [30, 60];
    cfg.benchmark.stage09_P_grid = [4, 6];
    cfg.benchmark.stage09_T_grid = [4, 6];
    cfg.benchmark.stage09_case_limit = 16;

    % ---------------------------
    % run_stages execution policy note
    % ---------------------------
    % The authoritative stage default mode policy is centralized in
    % run_stages/rs_apply_parallel_policy.m.
    %
    % Fields such as cfg.stageXX.use_parallel in this file are kept as
    % conservative direct-call fallbacks for stage functions that still read
    % a local use_parallel flag internally. They should not be interpreted
    % as the project-wide default execution mode.

    % ============================================================
    % Geodetic anchor and time-base configuration
    % =============================================================
    cfg.geo = struct();

    % Master switch:
    % false -> legacy abstract regional frame
    % true  -> geodetic-anchored regional frame with Earth rotation support
    cfg.geo.enable_geodetic_anchor = true;

    % Representative protected-zone center (non-sensitive open-ocean anchor)
    cfg.geo.lat0_deg = 30.0;
    cfg.geo.lon0_deg = -160.0;
    cfg.geo.h0_m     = 0.0;

    % Optional local-frame naming convention
    cfg.geo.local_frame = 'ENU';

    % WGS84 ellipsoid constants
    cfg.geo.earth_model = 'WGS84';
    cfg.geo.a_m  = 6378137.0;                 % semi-major axis [m]
    cfg.geo.f    = 1 / 298.257223563;         % flattening [-]
    cfg.geo.b_m  = cfg.geo.a_m * (1 - cfg.geo.f);
    cfg.geo.e2   = 2*cfg.geo.f - cfg.geo.f^2; % first eccentricity squared

    cfg.geo.lat0_rad = deg2rad(cfg.geo.lat0_deg);
    cfg.geo.lon0_rad = deg2rad(cfg.geo.lon0_deg);

    if cfg.geo.enable_geodetic_anchor
        cfg.meta.scene_mode = 'geodetic';
    else
        cfg.meta.scene_mode = 'abstract';
    end

    % ============================================================
    % Global time-base and Earth rotation configuration
    % =============================================================
    cfg.time = struct();

    % Global reference epoch for all geodetic/ECI-ECEF transformations
    cfg.time.epoch_utc = '2026-01-01 00:00:00';

    % Earth rotation model
    % 'simple' means a lightweight GMST/Earth-spin model sufficient for current stage
    cfg.time.earth_rotation_model = 'simple';

    % Earth rotation rate [rad/s]
    cfg.time.omega_ie_radps = 7.2921150e-5;

    % Time system label (for documentation / future extension)
    cfg.time.time_system = 'UTC';

    % Whether future stages should output timestamps relative to epoch
    cfg.time.output_relative_time = true;

    % ---------------------------
    % Random seed
    % ---------------------------
    cfg.random = struct();
    cfg.random.seed = 20260308;

    % ---------------------------
    % Debug options
    % ---------------------------
    cfg.debug = struct();
    cfg.debug.verbose = true;
    cfg.debug.save_intermediate = true;
    cfg.debug.make_dummy_plot = false;

    % ---------------------------
    % Placeholder experiment params
    % Stage00 only stores minimal placeholders.
    % Later stages will gradually expand these fields.
    % ---------------------------
    cfg.task = struct();
    cfg.task.name = 'disk_entry_static_inversion';

    cfg.disk = struct();
    cfg.disk.R_D_km  = 1000;
    cfg.disk.R_in_km = 3000;

    cfg.window = struct();
    cfg.window.Tw_s = 60;

    cfg.sensor = struct();
    cfg.sensor.sigma_angle_deg = 5 / 3600; % 5 arcsec

    cfg.walker = struct();
    cfg.walker.h_km_list   = [800, 1000, 1200];
    cfg.walker.i_deg_list  = [53, 70, 86];
    cfg.walker.P_list      = [6, 8, 10];
    cfg.walker.T_list      = [8, 12, 16];

    cfg.notes = 'Stage00 bootstrap config only.';

    % ---------------------------
    % Stage01 scenario parameters
    % ---------------------------
    cfg.stage01 = struct();

    % Protected disk / entry boundary
    cfg.stage01.disk_center_xy_km = [0, 0];
    cfg.stage01.R_D_km = 1000;
    cfg.stage01.R_in_km = 3000;

    % Nominal entry family
    cfg.stage01.num_nominal_entry_points = 12;

    % Heading family (relative to center-seeking heading)
    cfg.stage01.heading_offsets_deg = [0, -30, 30, -60, 60];

    % Critical family switches
    cfg.stage01.enable_critical_C1 = true;  % track-plane-aligned entry
    cfg.stage01.enable_critical_C2 = true;  % small-crossing-angle entry

    % Critical family representative settings
    cfg.stage01.critical_C1_y_offset_km = 500;
    cfg.stage01.critical_C2_start_angle_deg = 90;
    cfg.stage01.critical_C2_heading_offset_deg = -10;

    % Plot
    cfg.stage01.make_plot = false;
    cfg.stage01.axis_limit_km = 5500;
    cfg.stage01.parallel_pool_profile = 'local';
    cfg.stage01.parallel_num_workers = [];
    cfg.stage01.auto_start_pool = true;

    % ---------------------------
    % Stage02 VTC-HGV trajectory generation parameters
    % ---------------------------
    cfg.stage02 = struct();

    % Reference geographic origin for the abstract regional frame
    % (public-safe abstract anchor, not a real defended asset)
    cfg.stage02.phi_ref_deg = 0.0;      % reference latitude
    cfg.stage02.lambda_ref_deg = 0.0;   % reference longitude
    cfg.stage02.Re_m = 6378137;

    % Initial HGV state (representative public values)
    cfg.stage02.v0_mps = 5500;
    cfg.stage02.h0_m = 50000;
    cfg.stage02.theta0_deg = -3.0;      % flight-path angle

    % Default control templates
    cfg.stage02.alpha_nominal_deg = 11.0;
    cfg.stage02.bank_nominal_deg  = 0.0;

    cfg.stage02.alpha_heading_deg = 11.0;
    cfg.stage02.bank_heading_deg  = 0.0;

    cfg.stage02.alpha_c1_deg = 11.0;
    cfg.stage02.bank_c1_deg  = 0.0;

    cfg.stage02.alpha_c2_deg = 11.0;
    cfg.stage02.bank_c2_deg  = 8.0;

    % Time settings
    cfg.stage02.t0_s = 0;
    cfg.stage02.Tmax_s = 800;
    cfg.stage02.Ts_s = 1.0;

    % Stop conditions
    cfg.stage02.h_min_m = 15000;
    cfg.stage02.h_max_m = 120000;
    cfg.stage02.v_min_mps = 1500;
    cfg.stage02.v_max_mps = 9000;

    % A loose "task completion" radius in the abstract regional frame
    cfg.stage02.capture_radius_km = 1.2 * cfg.stage01.R_D_km;

    % Plotting
    cfg.stage02.make_plot = true;
    cfg.stage02.plot_num_cases_each_family = 3;

    % Summary / plot options
    cfg.stage02.make_plot_3d = true;
    cfg.stage02.example_entry_theta_deg = 0;   % choose one entry point by angle
    cfg.stage02.example_show_heading_offsets = [0, -30, 30, -60, 60];
    cfg.stage02.example_include_critical = true;

    % Event settings
    cfg.stage02.enable_landing_event = true;   % ground-impact style termination
    cfg.stage02.enable_task_capture_event = true;

    % Parallel options
    % NOTE:
    %   Project-wide default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is only the fallback when stage02_hgv_nominal is
    %   called directly without a wrapper-provided opts.mode.
    cfg.stage02.use_parallel = false;
    cfg.stage02.auto_start_pool = true;
    cfg.stage02.parallel_pool_profile = 'threads';
    cfg.stage02.parallel_num_workers = [];
    cfg.stage02.log_each_case = true;

    % 3D explanation plot options
    cfg.stage02.make_plot_3d = true;
    cfg.stage02.example_entry_theta_deg = 0;      % choose one entry point by angle
    cfg.stage02.example_show_heading_offsets = [0, -30, 30, -60, 60];
    cfg.stage02.example_include_critical = true;

    % ---------------------------
    % Stage03 Walker + visibility parameters
    % ---------------------------
    cfg.stage03 = struct();

    % Baseline single-layer Walker for visibility pipeline
    cfg.stage03.h_km = 1000;
    cfg.stage03.i_deg = 70;
    cfg.stage03.P = 8;
    cfg.stage03.T = 12;
    cfg.stage03.F = 1;

    % Sensor settings
    cfg.stage03.max_range_km = 5000;
    cfg.stage03.min_elevation_deg = 0;     % keep first version simple
    cfg.stage03.require_earth_occlusion_check = true;

    % Time alignment
    cfg.stage03.use_stage02_time_grid = true;

    % Plot / example settings
    cfg.stage03.make_plot = true;
    cfg.stage03.example_case_id = 'N01';
    cfg.stage03.example_show_top_k_sats = 6;

    % Stage03.1 visibility refinement
    cfg.stage03.max_range_km = 3500;               % tighten from 5000
    cfg.stage03.require_earth_occlusion_check = true;

    % Additional viewing-geometry constraint
    cfg.stage03.enable_offnadir_constraint = true;
    cfg.stage03.max_offnadir_deg = 65;             % first refined setting

    % If you later prefer elevation-style condition
    cfg.stage03.enable_min_elevation_constraint = false;
    cfg.stage03.min_elevation_deg = 5;

    % Parallel options
    % NOTE:
    %   Project-wide default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is only the fallback when stage03_visibility_pipeline
    %   is called directly without a wrapper-provided opts.mode.
    cfg.stage03.use_parallel = false;
    cfg.stage03.auto_start_pool = true;
    cfg.stage03.parallel_pool_profile = 'local';   % 'threads' or 'local'
    cfg.stage03.parallel_num_workers = [];         % [] means default
    cfg.stage03.log_each_case = true;

    % ---------------------------
    % Stage04 windowed information matrix parameters
    % ---------------------------
    cfg.stage04 = struct();

    % Window settings
    cfg.stage04.Tw_s = 60;          % baseline window length
    cfg.stage04.window_step_s = 5;  % slide step for t0 scan

    % Angular measurement precision
    cfg.stage04.sigma_angle_deg = 5 / 3600;   % 5 arcsec
    cfg.stage04.sigma_angle_rad = deg2rad(cfg.stage04.sigma_angle_deg);

    % Numerical regularization
    cfg.stage04.eps_reg = 1e-12;

    % Plot / example settings
    cfg.stage04.make_plot = true;
    cfg.stage04.log_each_case = true;
    cfg.stage04.example_case_id = 'N01';
    cfg.stage04.example_compare_case_ids = {'N01','H01_+60','C2_small_crossing_angle'};

    % Parallel options
    % NOTE:
    %   Wrapper-level default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is a local fallback for direct stage04 calls.
    cfg.stage04.use_parallel = false;
    cfg.stage04.auto_start_pool = true;
    cfg.stage04.parallel_pool_profile = cfg.stage03.parallel_pool_profile;
    cfg.stage04.parallel_num_workers = cfg.stage03.parallel_num_workers;

    % ============================================================
    % Stage04G.7 margin-threshold calibration
    % ============================================================
    % gamma_mode:
    %   'fixed'             -> use cfg.stage04.gamma_req_fixed directly
    %   'nominal_quantile'  -> calibrate from nominal-family lambda_worst quantile
    cfg.stage04.gamma_mode = 'nominal_quantile';

    % Used when gamma_mode = 'fixed'
    cfg.stage04.gamma_req_fixed = 1.0;

    % Used when gamma_mode = 'nominal_quantile'
    % Recommended baseline: 0.50 (nominal-family median)
    cfg.stage04.gamma_quantile = 0.50;

    % Safety floor to avoid degenerate/too-small threshold
    cfg.stage04.gamma_floor = 1.0;

    % ---------------------------
    % Stage05 nominal Walker static inversion
    % ---------------------------
    cfg.stage05 = struct();

    % Stage05.1: fixed-height first-pass scan over (i, P, T)
    cfg.stage05.family_scope = 'nominal';
    cfg.stage05.gamma_source = 'stage04_nominal_quantile';
    cfg.stage05.h_fixed_km = 1000;

    % coarse search grid
    cfg.stage05.i_grid_deg = [30 40 50 60 70 80 90];
    cfg.stage05.P_grid = [4 6 8 10 12];
    cfg.stage05.T_grid = [4 6 8 10 12 16];

    % reserved for Stage05.2
    cfg.stage05.require_pass_ratio = 1.0;
    cfg.stage05.require_D_G_min = 1.0;
    cfg.stage05.rank_rule = 'min_Ns_then_max_DG';

    % ---------------------------
    % Stage05 nominal Walker static inversion
    % ---------------------------
    cfg.stage05 = struct();

    % Stage05 scope
    cfg.stage05.family_scope = 'nominal';
    cfg.stage05.gamma_source = 'stage04_nominal_quantile';

    % Stage05.1 / 05.2:
    % first-pass scan over (i, P, T) with fixed h and fixed Walker phasing F
    cfg.stage05.h_fixed_km = 1000;
    cfg.stage05.F_fixed = 1;

    % coarse search grid
    cfg.stage05.i_grid_deg = [30 40 50 60 70 80 90];
    cfg.stage05.P_grid = [4 6 8 10 12];
    cfg.stage05.T_grid = [4 6 8 10 12 16];

    % feasibility rule for Stage05.2
    cfg.stage05.require_pass_ratio = 1.0;
    cfg.stage05.require_D_G_min = 1.0;

    % ranking rule for feasible candidates
    cfg.stage05.rank_rule = 'min_Ns_then_max_DG';

    % parallel options
    % NOTE:
    %   Wrapper-level default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is a local fallback for direct stage05 calls.
    cfg.stage05.use_parallel = false;
    cfg.stage05.auto_start_pool = true;
    cfg.stage05.parallel_pool_profile = 'local';   % 'threads' or 'local'
    cfg.stage05.parallel_num_workers = [];           % [] means default
    cfg.stage05.prefer_thread_pool_for_batch = true;

    % early-stop options
    cfg.stage05.use_early_stop = true;
    cfg.stage05.hard_case_first = true;

    % logging / progress
    cfg.stage05.use_live_progress = true;
    cfg.stage05.progress_every = 1;   % print every N completed grid points

    % cache size control
    cfg.stage05.save_eval_bank = false;

    % optional plotting
    cfg.stage05.make_plot = false;
    cfg.stage05.example_case_id = 'N01';

    % ---------------------------
    % Stage06 heading-extended Walker static inversion
    % ---------------------------
    cfg.stage06 = struct();

    % Stage06 scope
    cfg.stage06.family_scope = 'heading_extended';
    cfg.stage06.family_source = 'stage02_nominal';
    cfg.stage06.family_mode = 'small_then_full';

    % Named heading sets
    cfg.stage06.heading_offsets_small_deg = [0, -30, 30];
    cfg.stage06.heading_offsets_full_deg  = [0, -30, 30, -60, 60];

    % Active set selector for single-run mode
    cfg.stage06.active_heading_set_name = 'small';   % 'small' / 'full' / 'custom'

    % If active_heading_set_name = 'custom', use this explicit vector
    cfg.stage06.active_heading_offsets_custom_deg = [0, -30, 30];

    % Resolve active heading offsets
    switch lower(string(cfg.stage06.active_heading_set_name))
        case "small"
            cfg.stage06.active_heading_offsets_deg = cfg.stage06.heading_offsets_small_deg;
        case "full"
            cfg.stage06.active_heading_offsets_deg = cfg.stage06.heading_offsets_full_deg;
        case "custom"
            cfg.stage06.active_heading_offsets_deg = cfg.stage06.active_heading_offsets_custom_deg;
        otherwise
            error('Unknown cfg.stage06.active_heading_set_name: %s', cfg.stage06.active_heading_set_name);
    end

    % Run tag (used in filenames)
    cfg.stage06.run_tag = char(cfg.stage06.active_heading_set_name);

    % Search grid
    cfg.stage06.h_fixed_km = 1000;
    cfg.stage06.F_fixed = 1;
    cfg.stage06.i_grid_deg = [30 40 50 60 70 80 90];
    cfg.stage06.P_grid = [4 6 8 10 12];
    cfg.stage06.T_grid = [4 6 8 10 12 16];

    % Criteria
    cfg.stage06.require_pass_ratio = cfg.stage05.require_pass_ratio;
    cfg.stage06.require_D_G_min = cfg.stage05.require_D_G_min;
    cfg.stage06.rank_rule = cfg.stage05.rank_rule;

    % Gamma threshold source
    cfg.stage06.gamma_source = 'inherit_stage04';

    % Parallel / logging
    % NOTE:
    %   Wrapper-level default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is a local fallback for direct stage06 calls.
    cfg.stage06.use_parallel = false;
    cfg.stage06.auto_start_pool = cfg.stage05.auto_start_pool;
    cfg.stage06.parallel_pool_profile = cfg.stage05.parallel_pool_profile;
    cfg.stage06.parallel_num_workers = cfg.stage05.parallel_num_workers;
    cfg.stage06.prefer_thread_pool_for_batch = true;

    % Early stop
    cfg.stage06.use_early_stop = cfg.stage05.use_early_stop;
    cfg.stage06.hard_case_first = false;

    % Live progress
    cfg.stage06.use_live_progress = cfg.stage05.use_live_progress;
    cfg.stage06.progress_every = cfg.stage05.progress_every;
    cfg.stage06.save_eval_bank = false;

    % Output naming
    cfg.stage06.output_tag = 'heading_extended';

    % Self-check
    cfg.stage06.enable_self_check = true;
    cfg.stage06.expected_nominal_case_count = 12;
    cfg.stage06.expected_small_family_size = 36;
    cfg.stage06.expected_full_family_size = 60;

    % ---------------------------
    % Stage06 batch mode
    % ---------------------------
    cfg.stage06.batch = struct();

    % Master switch
    cfg.stage06.batch.enable = true;

    % Each entry is one heading-offset family to run
    cfg.stage06.batch.run_tags = {'small', 'full'};
    cfg.stage06.batch.heading_offset_sets = { ...
        [0, -30, 30], ...
        [0, -30, 30, -60, 60] ...
        };

    % Which sub-stages to execute in batch
    cfg.stage06.batch.run_scope   = true;
    cfg.stage06.batch.run_family  = true;
    cfg.stage06.batch.run_search  = true;
    cfg.stage06.batch.run_compare = true;
    cfg.stage06.batch.run_plot    = true;

        % ---------------------------
    % Stage07: reference-Walker-based critical geometry analysis
    % ---------------------------
    cfg.stage07 = struct();

    % Global run tag
    cfg.stage07.run_tag = 'critical';

    % Stage07.1 main philosophy:
    % first fix one reference Walker, then define C1/C2 relative to it.
    cfg.stage07.reference_walker_source = 'stage05_nominal';

    % selection rule:
    %   'frontier_near_feasible'  -> choose feasible point with D_G_min just above threshold
    %   'best_feasible'           -> directly use Stage05 summary.best_feasible
    cfg.stage07.reference_selection_rule = 'frontier_near_feasible';

    % feasibility thresholds inherited from Stage05/06 logic
    cfg.stage07.require_D_G_min = 1.0;
    cfg.stage07.require_pass_ratio = 1.0;

    % tie-break order for frontier-near selection
    % 1) smaller positive margin (D_G_min - require_D_G_min)
    % 2) smaller Ns
    % 3) smaller i_deg
    cfg.stage07.reference_tiebreak_order = {'margin_to_DG', 'Ns', 'i_deg'};

    % whether to force h/F from Stage05 row if present
    cfg.stage07.default_h_km = 1000;
    cfg.stage07.default_F = 1;

    % for later Stage07.2/07.3
    cfg.stage07.coverage_good_threshold = 0.5;
    cfg.stage07.angle_bad_threshold_deg = 10;
    cfg.stage07.lambda_bad_factor = 1.0;
    cfg.stage07.fallback_gamma_req = NaN;

    % -------------------------------------------------
    % Stage07.2: reference-Walker-based critical scope
    % -------------------------------------------------

    % Whether Stage07 C1/C2 are explicitly defined relative to reference Walker
    cfg.stage07.is_reference_relative = true;

    % Shared heading scan setup (used in later Stage07.3)
    cfg.stage07.heading_scan = struct();
    cfg.stage07.heading_scan.enable = true;
    cfg.stage07.heading_scan.step_deg = 5;
    cfg.stage07.heading_scan.max_abs_offset_deg = 90;
    cfg.stage07.heading_scan.min_heading_deg = 0;
    cfg.stage07.heading_scan.max_heading_deg = 360;
    cfg.stage07.heading_scan.wrap_mode = '360';

    % -------------------------------------------------
    % C1: track-plane-aligned entry
    % -------------------------------------------------
    cfg.stage07.C1 = struct();
    cfg.stage07.C1.mode_id = 'C1_trackplane';
    cfg.stage07.C1.description = ['Heading aligned with the local ground-track ', ...
        'direction induced by the reference Walker orbital plane.'];
    cfg.stage07.C1.selection_rule = 'closest_trackplane_heading';
    cfg.stage07.C1.use_both_branches = true;      % asc / desc local branches
    cfg.stage07.C1.keep_nearest_branch_only = true;
    cfg.stage07.C1.max_branch_count = 1;

    % -------------------------------------------------
    % C2: small-intersection-angle entry
    % -------------------------------------------------
    cfg.stage07.C2 = struct();
    cfg.stage07.C2.mode_id = 'C2_smallangle';
    cfg.stage07.C2.description = ['Heading chosen from local scan under fixed reference Walker, ', ...
        'subject to high dual coverage and minimal LOS crossing angle / degraded geometry.'];
    cfg.stage07.C2.selection_rule = 'scan_heading_under_reference_walker';
    cfg.stage07.C2.use_scan = true;

    % Candidate acceptance thresholds for C2 later selection
    cfg.stage07.C2.require_high_coverage = 0.8;   % later Stage07.3 can tighten/relax
    cfg.stage07.C2.primary_objective = 'min_mean_los_angle';
    cfg.stage07.C2.secondary_objective = 'min_lambda_worst';
    cfg.stage07.C2.tertiary_objective = 'min_D_G_min';

    % whether fallback to nominal heading is allowed
    % new Stage07 should forbid silent fallback
    cfg.stage07.C2.allow_fallback_nominal = false;

    % -------------------------------------------------
    % Stage07 danger / diagnostic thresholds
    % -------------------------------------------------
    cfg.stage07.danger = struct();
    cfg.stage07.danger.coverage_good_threshold = 0.8;
    cfg.stage07.danger.angle_bad_threshold_deg = 10;
    cfg.stage07.danger.D_G_bad_threshold = 1.0;
    cfg.stage07.danger.lambda_bad_factor = 1.0;   % lambda_worst < lambda_bad_factor * gamma_req

    % For later representative entry sampling
    cfg.stage07.entry_sampling = struct();
    cfg.stage07.entry_sampling.enable = true;
    cfg.stage07.entry_sampling.max_entry_count = 12;
    cfg.stage07.entry_sampling.rule = 'all_stage02_nominal_entries';

    % -------------------------------------------------
    % Stage07.4: critical example selection
    % -------------------------------------------------
    cfg.stage07.selection = struct();

    % nominal sample definition
    cfg.stage07.selection.nominal_heading_offset_deg = 0;

    % C1 selection
    cfg.stage07.selection.C1_max_distance_deg = 10;   % within 10 deg to nearest track-plane heading
    cfg.stage07.selection.C1_prefer_smaller_DG = true;

    % C2 selection
    cfg.stage07.selection.C2_require_high_coverage = cfg.stage07.danger.coverage_good_threshold;
    cfg.stage07.selection.C2_exclude_C1_neighborhood_deg = 10;  % avoid selecting same local mode as C1
    cfg.stage07.selection.C2_prefer_min_DG = true;
    cfg.stage07.selection.C2_secondary_prefer_min_lambda = true;
    cfg.stage07.selection.C2_tertiary_prefer_min_angle = true;

    % whether to keep only entries with complete nominal+C1+C2 triplets
    cfg.stage07.selection.require_complete_triplet = false;

    % -------------------------------------------------
    % Stage07.5: plotting
    % -------------------------------------------------
    cfg.stage07.plot = struct();

    % figure output directory
    cfg.stage07.plot.fig_dirname = 'figs';

    % representative entries used for heading-risk curves
    % rule:
    %   'lowest_C2_DG' -> choose entries with smallest C2 D_G_min
    cfg.stage07.plot.representative_entry_rule = 'lowest_C2_DG';
    cfg.stage07.plot.n_representative_entry = 4;

    % whether to export plot data tables
    cfg.stage07.plot.export_plot_tables = true;

    % figure visibility
    cfg.stage07.plot.visible = 'off';   % 'on' or 'off'

    % save both png and fig
    cfg.stage07.plot.save_png = true;
    cfg.stage07.plot.save_fig = true;
    cfg.stage07.use_parallel = false;
    cfg.stage07.auto_start_pool = true;
    cfg.stage07.parallel_pool_profile = 'local';
    cfg.stage07.parallel_num_workers = [];
    cfg.stage07.prefer_thread_pool_for_batch = true;

    % ---------------------------
    % Stage08: window-length sensitivity scope
    % ---------------------------
    cfg.stage08 = struct();

    % global run tag
    cfg.stage08.run_tag = 'twscan';

    % Tw grid selector
    cfg.stage08.active_tw_grid_name = 'baseline';   % 'baseline' / 'dense' / 'custom'

    % recommended first-pass grid
    cfg.stage08.Tw_grid_baseline_s = [40 50 60 70 80 100];

    % optional denser / wider grid
    cfg.stage08.Tw_grid_dense_s = [30 40 50 60 70 80 90 100 120];

    % custom fallback
    cfg.stage08.Tw_grid_custom_s = [40 50 60 70 80 100];

    % always include current Stage04 baseline Tw
    cfg.stage08.require_include_current_Tw = true;

    % -------------------------------------------------
    % reference-walker source policy
    % -------------------------------------------------
    cfg.stage08.reference = struct();
    cfg.stage08.reference.use_stage07_primary = true;
    cfg.stage08.reference.include_stage05_best_feasible = true;

    % -------------------------------------------------
    % representative cases
    % -------------------------------------------------
    cfg.stage08.rep = struct();

    % if Stage07.6.1 paper scope exists, reuse its representative entries first
    cfg.stage08.rep.prefer_stage07_paper_scope = true;

    % fallback number of representative entries
    cfg.stage08.rep.n_representative_entry = 2;

    % keep a small and interpretable representative subset
    cfg.stage08.rep.max_nominal_count = 2;
    cfg.stage08.rep.max_C1_count = 2;
    cfg.stage08.rep.max_C2_count = 2;

    % family order used in representative subset / later plotting
    cfg.stage08.family_order = {'nominal','C1','C2'};

    % -------------------------------------------------
    % Stage08.4 small-grid search scope
    % -------------------------------------------------
    cfg.stage08.smallgrid = struct();
    cfg.stage08.smallgrid.enable = true;

    % build around primary reference Walker
    cfg.stage08.smallgrid.h_offsets_km = 0;
    cfg.stage08.smallgrid.i_offsets_deg = [-10 0 10];
    cfg.stage08.smallgrid.P_offsets = [-2 0 2];
    cfg.stage08.smallgrid.T_offsets = [-2 0 2];

    cfg.stage08.smallgrid.min_i_deg = 20;
    cfg.stage08.smallgrid.max_i_deg = 90;
    cfg.stage08.smallgrid.min_P = 2;
    cfg.stage08.smallgrid.min_T = 2;

    cfg.stage08.smallgrid.F_fixed = 1;
    cfg.stage08.smallgrid.round_to_integer = true;

    % prevent Stage08.1 from generating an overly large config table
    cfg.stage08.smallgrid.max_config_count = 64;

    % -------------------------------------------------
    % Stage08.2 representative scan
    % -------------------------------------------------
    cfg.stage08.scan = struct();
    cfg.stage08.scan.make_plot = true;

    % -------------------------------------------------
    % Stage08.3 casebank scan
    % -------------------------------------------------
    cfg.stage08.casebank = struct();
    cfg.stage08.casebank.make_plot = true;

    % -------------------------------------------------
    % Stage08.4 small-grid reduced inversion scan
    % -------------------------------------------------
    cfg.stage08.smallgrid.make_plot = true;

    % feasibility rule for reduced-grid screening
    cfg.stage08.smallgrid.require_DG_min = 1.0;
    cfg.stage08.smallgrid.require_pass_geom_ratio = 0.90;
    cfg.stage08.smallgrid.require_C2_pass_ratio = 0.50;

    % NOTE:
    %   Wrapper-level default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is a local fallback for direct Stage08 reduced-grid calls.
    cfg.stage08.smallgrid.use_parallel = false;
    cfg.stage08.smallgrid.max_workers = inf;   % 或者 8 / 12
    cfg.stage08.smallgrid.pool_idle_timeout_min = 120;
    cfg.stage08.smallgrid.progress_step = 1;   % every 1 task completion feedback
    cfg.stage08.smallgrid.disable_progress = false;
    cfg.stage08.smallgrid.prefer_thread_pool_for_batch = true;

    % -------------------------------------------------
    % Stage08.4b feasibility profile
    % -------------------------------------------------
    cfg.stage08.smallgrid.feasibility_profile = 'strict';  % 'relaxed' / 'medium' / 'strict'

    % -------------------------------------------------
    % Stage08.4c boundary window sensitivity
    % -------------------------------------------------
    cfg.stage08c = struct();

    % hard-case bank size
    cfg.stage08c.n_hard_nominal = 3;
    cfg.stage08c.n_hard_C1 = 3;
    cfg.stage08c.n_hard_C2 = 6;

    % weak-side small-grid
    cfg.stage08c.h_km_list = 1000;
    cfg.stage08c.i_deg_list = [50, 60];
    cfg.stage08c.PT_pairs = [ ...
        8, 4; ...
        8, 5; ...
        8, 6; ...
        10, 4; ...
        10, 5; ...
        12, 4; ...
        12, 5; ...
        14, 4; ...
        16, 4];

    cfg.stage08c.F = 1;

    % boundary feasibility rule
    cfg.stage08c.tail_hard_k = 3;
    cfg.stage08c.tail_C2_k = 2;
    cfg.stage08c.require_DG_min = 1.0;

    % parallel + progress
    % NOTE:
    %   Wrapper-level default mode is controlled by rs_apply_parallel_policy.m.
    %   use_parallel here is a local fallback for direct Stage08c calls.
    cfg.stage08c.use_parallel = false;
    cfg.stage08c.max_workers = inf;
    cfg.stage08c.progress_step = 1;
    cfg.stage08c.disable_progress = false;
    cfg.stage08c.prefer_thread_pool_for_batch = true;

    % plotting
    cfg.stage08c.make_plot = true;

    % ---------------------------
    % Stage09 inverse-design configuration
    % ---------------------------
    cfg.stage09 = struct();

    % ------------------------------------------------------------
    % Stage09 scheme switch
    % ------------------------------------------------------------
    % 'stage05_aligned'  : default Stage05-aligned domain/casebank for direct comparison
    % 'validation_small' : keep the current small-grid validation scheme
    % 'full_main'        : formal main scan inheriting Stage05/06 granularity
    % 'custom'           : fully manual control over search_domain / casebank
    cfg.stage09.scheme_type = 'stage05_aligned';

    % Run tag (auto-adjusted in stage09_prepare_cfg for preset schemes
    % unless you explicitly overwrite it)
    cfg.stage09.run_tag = 'inverse';

    % ------------------------------------------------------------
    % Window source
    % ------------------------------------------------------------
    % 'inherit_stage08_5' : use the recommended Tw from Stage08.5
    % 'manual'            : use cfg.stage09.Tw_manual_s
    cfg.stage09.Tw_source = 'inherit_stage08_5';
    cfg.stage09.Tw_manual_s = cfg.stage04.Tw_s;

    % Optional run_tag hint when locating Stage08.5 cache
    cfg.stage09.stage08_5_run_tag_hint = '';

    % ------------------------------------------------------------
    % Task / requirement description
    % ------------------------------------------------------------
    cfg.stage09.task_name = 'single_layer_walker_inverse_design';
    cfg.stage09.region_label = 'disk_defense_region';
    cfg.stage09.g_max_label = 'baseline';
    cfg.stage09.g_max_value = 15;
    cfg.stage09.g_max_unit = 'g';

    % ------------------------------------------------------------
    % Formal thresholds used by D-series
    % ------------------------------------------------------------
    cfg.stage09.gamma_source = 'inherit_stage04';
    cfg.stage09.gamma_req_manual = [];
    cfg.stage09.sigma_A_req = 1.0;
    cfg.stage09.sigma_A_req_unit = 'normalized';
    cfg.stage09.dt_crit_s = 60;

    % ------------------------------------------------------------
    % Task-output projection C_A
    % ------------------------------------------------------------
    cfg.stage09.CA_mode = 'position_xyz';   % 'position_xyz' / 'custom'
    cfg.stage09.CA_custom = eye(3);
    cfg.stage09.CA_label = 'task-position-projection';

    % ------------------------------------------------------------
    % Search domain
    % NOTE:
    %   These values are placeholders and may be overwritten by
    %   stage09_prepare_cfg according to cfg.stage09.scheme_type.
    % ------------------------------------------------------------
    cfg.stage09.search_domain = struct();
    cfg.stage09.search_domain.h_grid_km = cfg.stage05.h_fixed_km;
    cfg.stage09.search_domain.i_grid_deg = cfg.stage05.i_grid_deg;
    cfg.stage09.search_domain.P_grid = cfg.stage05.P_grid;
    cfg.stage09.search_domain.T_grid = cfg.stage05.T_grid;
    cfg.stage09.search_domain.F_fixed = cfg.stage05.F_fixed;

    % Optional controls
    cfg.stage09.search_domain.round_to_integer = true;
    cfg.stage09.search_domain.max_config_count = inf;

    % ------------------------------------------------------------
    % Casebank scheme for Stage09
    % NOTE:
    %   These values may also be overwritten by stage09_prepare_cfg
    %   according to cfg.stage09.scheme_type.
    % ------------------------------------------------------------
    % 'nominal_only'     : nominal all only (Stage05-aligned default)
    % 'validation_small' : nominal all + heading subset + critical all
    % 'full74'           : nominal all + heading all + critical all
    % 'custom'           : manual control below
    cfg.stage09.casebank_mode = 'nominal_only';

    cfg.stage09.casebank_include_nominal = true;
    cfg.stage09.casebank_include_heading = false;
    cfg.stage09.casebank_include_critical = false;

    % For validation_small/custom modes
    cfg.stage09.casebank_heading_subset_max = 0;

    % heading selection mode when subset is used
    % 'first' : take the first K heading cases
    cfg.stage09.casebank_heading_subset_mode = 'first';

    % ------------------------------------------------------------
    % Ranking / boundary extraction
    % ------------------------------------------------------------
    cfg.stage09.rank_rule = 'min_Ns_then_max_joint_margin';
    cfg.stage09.enable_stage05_compatible_feasible = true;
    cfg.stage09.enable_joint_feasible = true;
    cfg.stage09.plot_h_slice_km = cfg.stage05.h_fixed_km;
    cfg.stage09.refPT_mode = 'all_theta_min_pairs';

    % ------------------------------------------------------------
    % Output controls
    % ------------------------------------------------------------
    cfg.stage09.make_plot = false;
    cfg.stage09.save_eval_bank = false;

    % ------------------------------------------------------------
    % Stage09.2 numeric kernel controls
    % ------------------------------------------------------------
    cfg.stage09.wr_reg_eps = 1e-9;
    cfg.stage09.wr_eig_floor = 1e-10;
    cfg.stage09.wr_inv_mode = 'eig_floor';
    cfg.stage09.A_metric_mode = 'max_eig_rms';
    cfg.stage09.force_symmetric = true;

    % ------------------------------------------------------------
    % Stage09.3 single-design evaluator controls
    % ------------------------------------------------------------
    cfg.stage09.require_DG_min = cfg.stage05.require_D_G_min;
    cfg.stage09.require_DA_min = 1.0;
    cfg.stage09.require_DT_min = 1.0;
    cfg.stage09.require_pass_ratio = cfg.stage05.require_pass_ratio;

    % For formal scans, I recommend false.
    % For smoke tests, true can save time.
    cfg.stage09.use_early_stop = false;
    cfg.stage09.use_parallel = true;
    cfg.stage09.auto_start_pool = true;
    cfg.stage09.parallel_pool_profile = 'local';
    cfg.stage09.parallel_num_workers = [];
    cfg.stage09.use_live_progress = true;
    cfg.stage09.disable_progress = false;
    cfg.stage09.prefer_thread_pool_for_batch = true;

    cfg.stage09.visibility_min_for_custody = 2;
    cfg.stage09.save_case_window_bank = false;

    % ------------------------------------------------------------
    % Stage09.4 feasible-domain scan controls
    % ------------------------------------------------------------
    cfg.stage09.scan_case_limit = inf;
    cfg.stage09.scan_theta_limit = inf;
    cfg.stage09.scan_log_every = 10;
    cfg.stage09.sort_full_table = true;
    cfg.stage09.write_csv = true;

    % ---------------------------
    % Stage10 structured-spectrum / screening package
    % ---------------------------
    cfg.stage10 = struct();

    % Official public entry of Stage10:
    %   'all'                  : run Stage10.A -> F
    %   'A','B','B1','C','D','E','E1','F' : run a single sub-stage
    %   'fft_validation_legacy': keep old Stage10.1 / 10.1d compatibility
    cfg.stage10.entry = 'all';

    % legacy mode switch kept only for compatibility with old Stage10.1 code
    cfg.stage10.mode = 'single_window_debug';

    cfg.stage10.run_tag = 'stage10';

    % source policy
    cfg.stage10.case_source = 'inherit_stage09_casebank';
    cfg.stage10.theta_source = 'manual';

    % representative manual theta for no-arg Stage10 runs
    cfg.stage10.manual_theta = struct();
    cfg.stage10.manual_theta.h_km = 1000;
    cfg.stage10.manual_theta.i_deg = 70;
    cfg.stage10.manual_theta.P = 8;
    cfg.stage10.manual_theta.T = 12;
    cfg.stage10.manual_theta.F = 1;

    % representative case/window
    cfg.stage10.case_index = 1;
    cfg.stage10.window_index = 1;
    cfg.stage10.clip_case_index = true;
    cfg.stage10.clip_window_index = true;

    % common numerical options
    cfg.stage10.force_symmetric = true;
    cfg.stage10.active_plane_min_trace = 0;
    cfg.stage10.shape_norm_mode = 'trace';
    cfg.stage10.fft_proxy_mode = 'template_active_support';
    cfg.stage10.eps_sb_norm = 'fro';
    cfg.stage10.compute_bounds = true;

    % legacy template-proxy defaults
    cfg.stage10.template_mode = 'fixed_isotropic_like';
    cfg.stage10.proxy_scale_mode = 'count_times_alpha';
    cfg.stage10.template_alpha_per_obs = 1000;
    cfg.stage10.template_shape_matrix = diag([0.50, 0.30, 0.20]);
    cfg.stage10.alpha_grid = [500, 750, 1000, 1250, 1500];
    cfg.stage10.alpha_fit_metric = 'lambda_abs_error';
    cfg.stage10.alpha_pick_rule = 'min_error';

    cfg.stage10.write_csv = true;
    cfg.stage10.save_mat_cache = true;
    cfg.stage10.make_plot = true;
    cfg.stage10.scan_log_every = 1;

    % ---------------------------
    % Stage10.A truth structure diagnostics
    % ---------------------------
    cfg.stage10A = struct();
    cfg.stage10A.run_tag = 'truthdiag';
    cfg.stage10A.case_source = cfg.stage10.case_source;
    cfg.stage10A.theta_source = cfg.stage10.theta_source;
    cfg.stage10A.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10A.case_index = cfg.stage10.case_index;
    cfg.stage10A.window_index = cfg.stage10.window_index;
    cfg.stage10A.clip_case_index = true;
    cfg.stage10A.clip_window_index = true;
    cfg.stage10A.anchor_mode = 'max_trace_active';
    cfg.stage10A.manual_anchor_plane = 1;
    cfg.stage10A.active_plane_min_trace = cfg.stage10.active_plane_min_trace;
    cfg.stage10A.force_symmetric = true;
    cfg.stage10A.make_plot = true;
    cfg.stage10A.write_csv = true;
    cfg.stage10A.save_mat_cache = true;
    cfg.stage10A.plot_visible = false;
    cfg.stage10A.entropy_eps = 1e-12;
    cfg.stage10A.scan_log_every = 1;

    % ---------------------------
    % Stage10.B bcirc prototype construction
    % ---------------------------
    cfg.stage10B = struct();
    cfg.stage10B.run_tag = 'bcircref';
    cfg.stage10B.case_source = cfg.stage10.case_source;
    cfg.stage10B.theta_source = cfg.stage10.theta_source;
    cfg.stage10B.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10B.case_index = cfg.stage10.case_index;
    cfg.stage10B.window_index = cfg.stage10.window_index;
    cfg.stage10B.clip_case_index = true;
    cfg.stage10B.clip_window_index = true;
    cfg.stage10B.anchor_mode = 'max_trace_active';
    cfg.stage10B.manual_anchor_plane = 1;
    cfg.stage10B.bcirc_firstcol_source = 'active_anchor_mean';
    cfg.stage10B.truth_reduced_source = 'active_anchor_mean';
    cfg.stage10B.make_plot = true;
    cfg.stage10B.write_csv = true;
    cfg.stage10B.save_mat_cache = true;

    % ---------------------------
    % Stage10.B.1 legal bcirc baseline
    % ---------------------------
    cfg.stage10B1 = struct();
    cfg.stage10B1.run_tag = 'bcirclegal';
    cfg.stage10B1.case_source = cfg.stage10.case_source;
    cfg.stage10B1.theta_source = cfg.stage10.theta_source;
    cfg.stage10B1.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10B1.case_index = cfg.stage10.case_index;
    cfg.stage10B1.window_index = cfg.stage10.window_index;
    cfg.stage10B1.clip_case_index = true;
    cfg.stage10B1.clip_window_index = true;
    cfg.stage10B1.anchor_mode = 'max_trace_active';
    cfg.stage10B1.manual_anchor_plane = 1;
    cfg.stage10B1.prototype_source = 'active_anchor_mean';
    cfg.stage10B1.force_block_symmetry = true;
    cfg.stage10B1.do_mirror_symmetrization = true;
    cfg.stage10B1.do_psd_projection = true;
    cfg.stage10B1.psd_floor = 0;
    cfg.stage10B1.make_plot = true;
    cfg.stage10B1.write_csv = true;
    cfg.stage10B1.save_mat_cache = true;
    cfg.stage10B1.scan_log_every = 1;

    % ---------------------------
    % Stage10.C FFT spectral validation
    % ---------------------------
    cfg.stage10C = struct();
    cfg.stage10C.run_tag = 'fftspec';
    cfg.stage10C.case_source = cfg.stage10.case_source;
    cfg.stage10C.theta_source = cfg.stage10.theta_source;
    cfg.stage10C.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10C.case_index = cfg.stage10.case_index;
    cfg.stage10C.window_index = cfg.stage10.window_index;
    cfg.stage10C.clip_case_index = true;
    cfg.stage10C.clip_window_index = true;
    cfg.stage10C.anchor_mode = 'max_trace_active';
    cfg.stage10C.manual_anchor_plane = 1;
    cfg.stage10C.prototype_source = 'active_anchor_mean';
    cfg.stage10C.mode_order = 'natural';
    cfg.stage10C.make_plot = true;
    cfg.stage10C.write_csv = true;
    cfg.stage10C.save_mat_cache = true;

    % ---------------------------
    % Stage10.D symmetry-breaking margin
    % ---------------------------
    cfg.stage10D = struct();
    cfg.stage10D.run_tag = 'margin';
    cfg.stage10D.case_source = cfg.stage10.case_source;
    cfg.stage10D.theta_source = cfg.stage10.theta_source;
    cfg.stage10D.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10D.case_index = cfg.stage10.case_index;
    cfg.stage10D.window_index = cfg.stage10.window_index;
    cfg.stage10D.clip_case_index = true;
    cfg.stage10D.clip_window_index = true;
    cfg.stage10D.anchor_mode = 'max_trace_active';
    cfg.stage10D.manual_anchor_plane = 1;
    cfg.stage10D.prototype_source = 'active_anchor_mean';
    cfg.stage10D.eps_norm_mode = 2;
    cfg.stage10D.make_plot = true;
    cfg.stage10D.write_csv = true;
    cfg.stage10D.save_mat_cache = true;

    % ---------------------------
    % Stage10.E small-grid screening benchmark
    % ---------------------------
    cfg.stage10E = struct();
    cfg.stage10E.run_tag = 'screen';
    cfg.stage10E.case_index = cfg.stage10.case_index;
    cfg.stage10E.window_index = cfg.stage10.window_index;
    cfg.stage10E.anchor_mode = 'max_trace_active';
    cfg.stage10E.manual_anchor_plane = 1;
    cfg.stage10E.prototype_source = 'active_anchor_mean';
    cfg.stage10E.grid_h_km = [900, 1000, 1100];
    cfg.stage10E.grid_i_deg = [60, 70, 80];
    cfg.stage10E.grid_P = [6, 8];
    cfg.stage10E.grid_T = [10, 12];
    cfg.stage10E.grid_F = 1;
    cfg.stage10E.threshold_truth = 2.0e4;
    cfg.stage10E.threshold_zero = 2.0e4;
    cfg.stage10E.threshold_bcirc = 1.0;
    cfg.stage10E.two_stage_rule = 'zero_pass_and_bcirc_nonnegative';
    cfg.stage10E.make_plot = true;
    cfg.stage10E.write_csv = true;
    cfg.stage10E.save_mat_cache = true;

    % ---------------------------
    % Stage10.E.1 refined rule
    % ---------------------------
    cfg.stage10E1 = struct();
    cfg.stage10E1.run_tag = 'screen_refine';
    cfg.stage10E1.case_index = cfg.stage10.case_index;
    cfg.stage10E1.window_index = cfg.stage10.window_index;
    cfg.stage10E1.anchor_mode = 'max_trace_active';
    cfg.stage10E1.manual_anchor_plane = 1;
    cfg.stage10E1.prototype_source = 'active_anchor_mean';
    cfg.stage10E1.grid_h_km = cfg.stage10E.grid_h_km;
    cfg.stage10E1.grid_i_deg = cfg.stage10E.grid_i_deg;
    cfg.stage10E1.grid_P = cfg.stage10E.grid_P;
    cfg.stage10E1.grid_T = cfg.stage10E.grid_T;
    cfg.stage10E1.grid_F = cfg.stage10E.grid_F;
    cfg.stage10E1.threshold_truth = cfg.stage10E.threshold_truth;
    cfg.stage10E1.threshold_zero = cfg.stage10E.threshold_zero;
    cfg.stage10E1.threshold_bcirc = cfg.stage10E.threshold_bcirc;
    cfg.stage10E1.make_plot = true;
    cfg.stage10E1.write_csv = true;
    cfg.stage10E1.save_mat_cache = true;

    % ---------------------------
    % Stage10.F final evidence pack
    % ---------------------------
    cfg.stage10F = struct();
    cfg.stage10F.run_tag = 'finalpack';
    cfg.stage10F.case_index = cfg.stage10.case_index;
    cfg.stage10F.window_index = cfg.stage10.window_index;
    cfg.stage10F.anchor_mode = 'max_trace_active';
    cfg.stage10F.manual_anchor_plane = 1;
    cfg.stage10F.prototype_source = 'active_anchor_mean';
    cfg.stage10F.manual_theta = cfg.stage10.manual_theta;
    cfg.stage10F.grid_h_km = cfg.stage10E1.grid_h_km;
    cfg.stage10F.grid_i_deg = cfg.stage10E1.grid_i_deg;
    cfg.stage10F.grid_P = cfg.stage10E1.grid_P;
    cfg.stage10F.grid_T = cfg.stage10E1.grid_T;
    cfg.stage10F.grid_F = cfg.stage10E1.grid_F;
    cfg.stage10F.threshold_truth = cfg.stage10E1.threshold_truth;
    cfg.stage10F.threshold_zero = cfg.stage10E1.threshold_zero;
    cfg.stage10F.threshold_bcirc = cfg.stage10E1.threshold_bcirc;
    cfg.stage10F.make_plot = true;
    cfg.stage10F.write_csv = true;
    cfg.stage10F.save_mat_cache = true;

    % ---------------------------
    % Stage11 tightened geometric certificate package
    % ---------------------------
    cfg.stage11 = struct();
    cfg.stage11.entry = 'all';
    cfg.stage11.run_tag = 'stage11';
    cfg.stage11.source_stage10_entry = 'E1';
    cfg.stage11.case_source = cfg.stage10.case_source;
    cfg.stage11.casebank_mode = cfg.stage09.casebank_mode;
    cfg.stage11.cache_mode = 'build_fresh_small';
    cfg.stage11.theta_source = 'config_grid';
    cfg.stage11.manual_theta = cfg.stage10.manual_theta;
    cfg.stage11.case_index = cfg.stage10.case_index;
    cfg.stage11.window_index = cfg.stage10.window_index;
    cfg.stage11.clip_case_index = true;
    cfg.stage11.clip_window_index = true;
    cfg.stage11.grid_h_km = cfg.stage10.manual_theta.h_km;
    cfg.stage11.grid_i_deg = cfg.stage10.manual_theta.i_deg;
    cfg.stage11.grid_P = cfg.stage10.manual_theta.P;
    cfg.stage11.grid_T = cfg.stage10.manual_theta.T;
    cfg.stage11.grid_F = cfg.stage10.manual_theta.F;
    cfg.stage11.threshold_truth = cfg.stage10E1.threshold_truth;
    cfg.stage11.threshold_zero = cfg.stage10E1.threshold_zero;
    cfg.stage11.threshold_bcirc = cfg.stage10E1.threshold_bcirc;
    cfg.stage11.two_stage_rule = cfg.stage10E.two_stage_rule;
    cfg.stage11.gamma_G = cfg.stage10E1.threshold_truth;
    cfg.stage11.force_symmetric = true;
    cfg.stage11.case_mode = 'tiny_manual';
    cfg.stage11.case_ids = ["N01"];
    cfg.stage11.window_mode = 'sparse';
    cfg.stage11.max_windows_per_case = 12;
    cfg.stage11.max_total_windows = 40;
    cfg.stage11.log_every_window = true;
    cfg.stage11.partition_mode = 'plane';
    cfg.stage11.rep_source = 'reference_library';
    cfg.stage11.reference_theta_source = 'manual';
    cfg.stage11.reference_theta = cfg.stage10.manual_theta;
    cfg.stage11.reference_case_index = cfg.stage10.case_index;
    cfg.stage11.reference_case_id = "N01";
    cfg.stage11.reference_window_index = cfg.stage10.window_index;
    cfg.stage11.reference_window_mode = 'multi_fixed';
    cfg.stage11.reference_window_indices = [1, 4, 8, 12];
    cfg.stage11.reference_select_mode = 'nearest_fro';
    cfg.stage11.unmatched_group_mode = 'zero_fallback';
    cfg.stage11.reference_fallback = 'invalid';
    cfg.stage11.enable_weak = true;
    cfg.stage11.enable_sub = true;
    cfg.stage11.enable_blk = false;
    cfg.stage11.enable_ablation = true;
    cfg.stage11.scan_log_every = 1;
    cfg.stage11.make_plot = true;
    cfg.stage11.write_csv = true;
    cfg.stage11.save_mat_cache = true;
    cfg.stage11.write_report = true;
    cfg.stage11.enable_diagnosis = true;
    cfg.stage11.export_window_diagnostics = true;
    cfg.stage11.export_case_diagnostics = true;
    cfg.stage11.max_diagnostic_rows = 50;
    cfg.stage11.diagnosis_verbose = true;
    cfg.stage11.use_parallel = false;

    % ---------------------------
    % Stage14 openD / RAAN mainline
    % ---------------------------
    cfg.stage14 = struct();
    cfg.stage14.use_parallel = true;
    cfg.stage14.auto_start_pool = true;
    cfg.stage14.parallel_pool_profile = 'local';
    cfg.stage14.parallel_num_workers = [];
    cfg.stage14.prefer_thread_pool_for_batch = true;
    cfg.stage14.use_live_progress = true;
    cfg.stage14.progress_every = 25;
    cfg.stage14.parallel = struct();
    cfg.stage14.parallel.enable = cfg.stage14.use_parallel;
    cfg.stage14.parallel.prefer_threads = strcmpi(cfg.stage14.parallel_pool_profile, 'threads');
    cfg.stage14.parallel.max_workers = cfg.stage14.parallel_num_workers;
    cfg.stage14.parallel.progress_every = cfg.stage14.progress_every;
end

