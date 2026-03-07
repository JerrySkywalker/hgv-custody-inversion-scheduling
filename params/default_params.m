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
end