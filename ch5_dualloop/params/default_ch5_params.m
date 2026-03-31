function cfg = default_ch5_params(scene_preset)
%DEFAULT_CH5_PARAMS  Chapter 5 default parameters built on project defaults.
%
% Optional input:
%   scene_preset = 'stress96' | 'ref128'
%
% Default:
%   stress96

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'stress96';
end

if exist('default_params', 'file') ~= 2
    error('default_params.m is not on path. Please run startup first.');
end

cfg = default_params();

cfg.phase_name = 'phase0';
cfg.output_root = fullfile(pwd, 'outputs', 'cpt5', cfg.phase_name);

cfg.time.t0 = cfg.stage02.t0_s;
cfg.time.tf = cfg.stage02.Tmax_s;
cfg.time.dt = cfg.stage02.Ts_s;

cfg.stage02.t0_s = cfg.time.t0;
cfg.stage02.Tmax_s = cfg.time.tf;
cfg.stage02.Ts_s = cfg.time.dt;

cfg.target = struct();
cfg.target.name = 'HGV_Demo';
cfg.target.model = 'stage02_engine_wrapped';

cfg.sensor = struct();
cfg.sensor.name = 'IR_Base';
cfg.sensor.max_range_km = cfg.stage03.max_range_km;
cfg.sensor.fov_deg = 5;

cfg.constellation = struct();
cfg.constellation.name = 'Walker_Base';
cfg.constellation.altitude_km = cfg.stage03.h_km;
cfg.constellation.inclination_deg = cfg.stage03.i_deg;
cfg.constellation.num_planes = cfg.stage03.P;
cfg.constellation.sats_per_plane = cfg.stage03.T;
cfg.constellation.phase_factor = cfg.stage03.F;

cfg.ch5 = struct();
cfg.ch5.profile_name = 'ch5_dynamic_profile_v1';
cfg.ch5.lat0_deg = 30.0;
cfg.ch5.lon0_deg = -160.0;
cfg.ch5.h0_m = 40000.0;
cfg.ch5.speed0_mps = 5000.0;
cfg.ch5.gamma0_deg = -2.0;
cfg.ch5.heading0_deg = 90.0;

cfg.ch5.max_track_sats = 2;

cfg.ch5.window_steps = 20;
cfg.ch5.custody_alpha = 0.65;
cfg.ch5.custody_gamma = 0.20;
cfg.ch5.custody_beta = 0.20;
cfg.ch5.custody_switch_penalty = 0.25;
cfg.ch5.custody_phi_threshold = 0.45;
cfg.ch5.custody_gap_weight = 1.20;
cfg.ch5.custody_outage_weight = 0.80;

% Phase 5D: longest-bad-run-first weights
cfg.ch5.custody_longest_bad_weight = 100.0;
cfg.ch5.custody_worst_gap_weight = 10.0;
cfg.ch5.custody_outage_frac_weight = 3.0;
cfg.ch5.custody_mean_gap_weight = 1.0;
cfg.ch5.custody_mean_future_weight = 0.05;
cfg.ch5.custody_switch_weight = 0.20;

cfg = apply_ch5_scene_preset(cfg, scene_preset);

cfg.notes = struct();
cfg.notes.phase = 'Fifth chapter isolated development';
cfg.notes.chapter4_code_modified = false;
cfg.notes.stage03_aligned = true;
cfg.notes.scene_preset = cfg.ch5.scene_preset;
end
