function cfg = default_ch5_params()
%DEFAULT_CH5_PARAMS  Chapter 5 default parameters for isolated phase development.
%
% This config is intentionally minimal, but includes the compatibility
% fields required by the Stage02/Stage03 engines.

cfg = struct();

cfg.phase_name = 'phase0';
cfg.output_root = fullfile(pwd, 'outputs', 'cpt5', cfg.phase_name);

% -------------------------------------------------------------------------
% Global time
% -------------------------------------------------------------------------
cfg.time = struct();
cfg.time.t0 = 0;
cfg.time.tf = 500;
cfg.time.dt = 1;
cfg.time.epoch_utc = datetime(2026, 1, 1, 0, 0, 0);

% -------------------------------------------------------------------------
% Basic chapter 5 semantic objects
% -------------------------------------------------------------------------
cfg.target = struct();
cfg.target.name = 'HGV_Demo';
cfg.target.model = 'stage02_engine_wrapped';

cfg.constellation = struct();
cfg.constellation.name = 'Walker_Demo';
cfg.constellation.altitude_km = 1000;
cfg.constellation.inclination_deg = 90;
cfg.constellation.num_planes = 6;
cfg.constellation.sats_per_plane = 4;
cfg.constellation.phase_factor = 1;

cfg.sensor = struct();
cfg.sensor.name = 'IR_Demo';
cfg.sensor.max_range_km = 5000;
cfg.sensor.fov_deg = 5;

% -------------------------------------------------------------------------
% Minimal Stage01 compatibility
% -------------------------------------------------------------------------
cfg.stage01 = struct();
cfg.stage01.disk_center_xy_km = [0, 0];

% -------------------------------------------------------------------------
% Minimal geodetic anchor compatibility
% -------------------------------------------------------------------------
cfg.geo = struct();
cfg.geo.enable_geodetic_anchor = true;
cfg.geo.lat0_deg = 30.0;
cfg.geo.lon0_deg = -160.0;
cfg.geo.h0_m = 0.0;

% -------------------------------------------------------------------------
% Minimal Stage02 compatibility
% -------------------------------------------------------------------------
cfg.stage02 = struct();

% Initial-state defaults
cfg.stage02.v0_mps = 5000.0;
cfg.stage02.theta0_deg = -2.0;
cfg.stage02.h0_m = 40000.0;
cfg.stage02.phi0_deg = 30.0;
cfg.stage02.lambda0_deg = -160.0;
cfg.stage02.sigma0_deg = 0.0;

% Control profile defaults
cfg.stage02.alpha_cmd_deg = 15.0;
cfg.stage02.bank_cmd_deg = 0.0;
cfg.stage02.alpha_nominal_deg = 15.0;
cfg.stage02.bank_nominal_deg = 0.0;
cfg.stage02.alpha_heading_deg = 15.0;
cfg.stage02.bank_heading_deg = 0.0;
cfg.stage02.use_heading_offset_as_bank_seed = false;
cfg.stage02.heading_offset_bank_gain_deg_per_deg = 0.0;

% Time / propagation settings
cfg.stage02.t0_s = 0.0;
cfg.stage02.Tmax_s = 500.0;
cfg.stage02.Ts_s = 1.0;

% Reference geometry / event settings
cfg.stage02.phi_ref_deg = cfg.geo.lat0_deg;
cfg.stage02.lambda_ref_deg = cfg.geo.lon0_deg;
cfg.stage02.Re_m = 6378137.0;
cfg.stage02.h_min_m = 20000.0;
cfg.stage02.h_max_m = 120000.0;
cfg.stage02.v_min_mps = 500.0;
cfg.stage02.v_max_mps = 9000.0;
cfg.stage02.enable_task_capture_event = false;
cfg.stage02.capture_radius_km = 1000.0;
cfg.stage02.enable_landing_event = true;

cfg.notes = struct();
cfg.notes.phase = 'Fifth chapter isolated development';
cfg.notes.chapter4_code_modified = false;
end
