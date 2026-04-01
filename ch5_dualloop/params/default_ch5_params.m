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

cfg.ch5.custody_longest_bad_weight = 100.0;
cfg.ch5.custody_worst_gap_weight = 10.0;
cfg.ch5.custody_outage_frac_weight = 3.0;
cfg.ch5.custody_mean_gap_weight = 1.0;
cfg.ch5.custody_mean_future_weight = 0.05;
cfg.ch5.custody_switch_weight = 0.20;

cfg.ch5.outer_update_steps = 40;
cfg.ch5.outer_horizon_steps = 60;
cfg.ch5.outer_prior_weight = 2.0;
cfg.ch5.outer_range_scale_km = 2000.0;

cfg.ch5.outerA_fit_window_steps = 25;
cfg.ch5.outerA_horizon_steps = 40;
cfg.ch5.outerA_state_dim = 3;

cfg.ch5.outerA_mrhat_w_phi = 0.55;
cfg.ch5.outerA_mrhat_w_nis = 0.25;
cfg.ch5.outerA_mrhat_w_cand = 0.20;

cfg.ch5.outerA_rho_max = 0.90;
cfg.ch5.outerA_std_eps = 1.0e-6;
cfg.ch5.outerA_pred_clip_phi = [-0.20, 1.20];
cfg.ch5.outerA_pred_clip_nis = [0.00, 6.00];
cfg.ch5.outerA_pred_clip_cand = [0.00, 1.20];

cfg.ch5.outerA_conservative_gain = 0.35;
cfg.ch5.outerA_nis_clip = 4.0;
cfg.ch5.outerA_inflation_cap = 2.0;

cfg.ch5.outerA_warn_threshold = 0.50;
cfg.ch5.outerA_trigger_threshold = 0.70;
cfg.ch5.outerA_omega_warn_threshold = 0.02;
cfg.ch5.outerA_omega_trigger_threshold = 0.05;

cfg.ch5.outerA_ridge_lambda = 1.0e-2;
cfg.ch5.outerA_rank_rel_tol = 1.0e-6;
cfg.ch5.outerA_rank_fallback_min = 2;

% ============================================================
% Phase 7A-4: single-support-dominant outerB
% ============================================================
cfg.ch5.ck_force_two_sat_in_warn = true;
cfg.ch5.ck_force_two_sat_in_trigger = true;
cfg.ch5.ck_force_two_sat_in_safe = false;
cfg.ch5.ck_allow_single_fallback = true;

cfg.ch5.ck_ref_dual_weight = 2.0;
cfg.ch5.ck_ref_single_weight = 1.5;
cfg.ch5.ck_ref_zero_weight = 2.0;
cfg.ch5.ck_ref_longest_single_weight = 1.2;
cfg.ch5.ck_ref_longest_zero_weight = 1.0;

cfg.ch5.ck_safe_dual_weight = 0.8;
cfg.ch5.ck_safe_single_weight = 0.6;
cfg.ch5.ck_safe_zero_weight = 0.8;
cfg.ch5.ck_safe_longest_single_weight = 0.6;
cfg.ch5.ck_safe_longest_zero_weight = 0.5;
cfg.ch5.ck_safe_base_weight = 1.0;
cfg.ch5.ck_safe_switch_weight = 0.8;

cfg.ch5.ck_warn_dual_weight = 2.0;
cfg.ch5.ck_warn_single_weight = 2.8;
cfg.ch5.ck_warn_zero_weight = 2.2;
cfg.ch5.ck_warn_longest_single_weight = 3.0;
cfg.ch5.ck_warn_longest_zero_weight = 1.8;
cfg.ch5.ck_warn_base_weight = 0.2;
cfg.ch5.ck_warn_switch_weight = 0.2;

cfg.ch5.ck_trigger_dual_weight = 2.4;
cfg.ch5.ck_trigger_single_weight = 3.5;
cfg.ch5.ck_trigger_zero_weight = 3.0;
cfg.ch5.ck_trigger_longest_single_weight = 4.0;
cfg.ch5.ck_trigger_longest_zero_weight = 2.4;
cfg.ch5.ck_trigger_base_weight = 0.05;
cfg.ch5.ck_trigger_switch_weight = 0.05;

cfg.ch5.ck_gate_warn_max_zero_ratio = 0.15;
cfg.ch5.ck_gate_warn_max_longest_zero = 4;
cfg.ch5.ck_gate_warn_max_longest_single = 5;

cfg.ch5.ck_gate_trigger_max_zero_ratio = 0.05;
cfg.ch5.ck_gate_trigger_max_longest_zero = 2;
cfg.ch5.ck_gate_trigger_max_longest_single = 3;

cfg.ch5.ck_gate_penalty = 1.0e3;

% Phase 7A-4 lexicographic control
cfg.ch5.ck_use_lexicographic_in_warn = true;
cfg.ch5.ck_use_lexicographic_in_trigger = true;

cfg = apply_ch5_scene_preset(cfg, scene_preset);

cfg.notes = struct();
cfg.notes.phase = 'Fifth chapter isolated development';
cfg.notes.chapter4_code_modified = false;
cfg.notes.stage03_aligned = true;
cfg.notes.scene_preset = cfg.ch5.scene_preset;
end
