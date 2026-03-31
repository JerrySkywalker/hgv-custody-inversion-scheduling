function cfg = default_ch5_params()
%DEFAULT_CH5_PARAMS  Chapter 5 default parameters built on project defaults.
%
% Key rule:
%   Reuse the main project config tree from default_params() so that
%   Stage02/Stage03 engines receive all required low-level fields.
%
% Chapter 5 only overrides a small set of fields.

% -------------------------------------------------------------------------
% Start from the full project default config
% -------------------------------------------------------------------------
if exist('default_params', 'file') ~= 2
    error('default_params.m is not on path. Please run startup first.');
end

cfg = default_params();

% -------------------------------------------------------------------------
% Chapter 5 phase / output identity
% -------------------------------------------------------------------------
cfg.phase_name = 'phase0';
cfg.output_root = fullfile(pwd, 'outputs', 'cpt5', cfg.phase_name);

% -------------------------------------------------------------------------
% Chapter 5 experiment time span
% Keep epoch_utc from default_params unless explicitly overwritten.
% -------------------------------------------------------------------------
cfg.time.t0 = 0;
cfg.time.tf = 500;
cfg.time.dt = 1;

% Keep Stage02 propagation horizon synchronized with chapter 5 experiment
cfg.stage02.t0_s = cfg.time.t0;
cfg.stage02.Tmax_s = cfg.time.tf;
cfg.stage02.Ts_s = cfg.time.dt;

% -------------------------------------------------------------------------
% Chapter 5 semantic labels
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
% Chapter 5 dedicated target-profile defaults
% These values are used by the wrapper, then mapped into Stage02 engine.
% -------------------------------------------------------------------------
cfg.ch5 = struct();
cfg.ch5.profile_name = 'ch5_dynamic_profile_v1';
cfg.ch5.lat0_deg = 30.0;
cfg.ch5.lon0_deg = -160.0;
cfg.ch5.h0_m = 40000.0;
cfg.ch5.speed0_mps = 5000.0;
cfg.ch5.gamma0_deg = -2.0;
cfg.ch5.heading0_deg = 90.0;

% -------------------------------------------------------------------------
% Keep a note for bookkeeping
% -------------------------------------------------------------------------
cfg.notes = struct();
cfg.notes.phase = 'Fifth chapter isolated development';
cfg.notes.chapter4_code_modified = false;
end
