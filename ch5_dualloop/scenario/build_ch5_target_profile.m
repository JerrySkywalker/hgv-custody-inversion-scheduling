function profile = build_ch5_target_profile(cfg)
%BUILD_CH5_TARGET_PROFILE  Build chapter 5 dedicated target profile.
%
% This profile is not copied from chapter 4 trajectory samples.
% It is a lightweight chapter-5-specific wrapper that can be mapped to
% the existing Stage02 propagation engine.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

profile = struct();

profile.name = 'ch5_dynamic_profile_v1';
profile.t0_s = cfg.time.t0;
profile.tf_s = cfg.time.tf;
profile.dt_s = cfg.time.dt;

% Entry / geometry seeds. These values are placeholders for now, but the
% interface is designed to be compatible with later refinement.
profile.lat0_deg = 30.0;
profile.lon0_deg = -160.0;
profile.h0_m = 40000.0;

profile.speed0_mps = 5000.0;
profile.gamma0_deg = -2.0;
profile.heading0_deg = 90.0;

% Phase-2.5A uses a dedicated profile label to distinguish it from chapter 4
% nominal/heading/critical case families.
profile.mode = 'ch5_dynamic';
profile.notes = 'Chapter 5 dedicated target profile for Stage02-engine wrapping';
end
