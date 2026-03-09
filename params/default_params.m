function cfg = default_params()
%DEFAULT_PARAMS Default configuration for the fresh-start Chapter 4 project.

    cfg = struct();

    % ---------------------------
    % Project metadata
    % ---------------------------
    cfg.project_name   = 'cpt4_disk_fresh';
    cfg.project_stage  = 'stage00';
    cfg.timestamp      = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    % ---------------------------
    % Paths
    % ---------------------------
    root_dir = fileparts(fileparts(mfilename('fullpath'))); % params -> root
    cfg.paths = struct();
    cfg.paths.root    = root_dir;
    cfg.paths.results = fullfile(root_dir, 'results');
    cfg.paths.cache   = fullfile(root_dir, 'results', 'cache');
    cfg.paths.logs    = fullfile(root_dir, 'results', 'logs');
    cfg.paths.figs    = fullfile(root_dir, 'results', 'figs');
    cfg.paths.tables  = fullfile(root_dir, 'results', 'tables');
    cfg.paths.bundles = fullfile(root_dir, 'results', 'bundles');

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
    cfg.stage01.make_plot = true;
    cfg.stage01.axis_limit_km = 5500;

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
    cfg.stage04.example_case_id = 'N01';
    cfg.stage04.example_compare_case_ids = {'N01','H01_+60','C2_small_crossing_angle'};

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
    cfg.stage05.use_parallel = true;
    cfg.stage05.auto_start_pool = true;
    cfg.stage05.parallel_pool_profile = 'local';   % 'threads' or 'local'
    cfg.stage05.parallel_num_workers = [];           % [] means default

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
    cfg.stage06.use_parallel = cfg.stage05.use_parallel;
    cfg.stage06.auto_start_pool = cfg.stage05.auto_start_pool;
    cfg.stage06.parallel_pool_profile = cfg.stage05.parallel_pool_profile;
    cfg.stage06.parallel_num_workers = cfg.stage05.parallel_num_workers;

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
end