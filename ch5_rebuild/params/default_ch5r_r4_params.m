function r4 = default_ch5r_r4_params()
%DEFAULT_CH5R_R4_PARAMS  Default tunable parameters for Phase R4.

r4 = struct();

% Hysteresis thresholds are defined relative to gamma_req.
r4.tau_low_ratio = 0.40;
r4.tau_high_ratio = 0.55;

% Minimum holding steps after switching.
r4.min_hold_steps_plus = 2;
r4.min_hold_steps_star = 1;

% Gain settings for policy-aware information proxy.
r4.gain_resource_coeff = 0.55;
r4.gain_shape_coeff = 0.25;

% Whether to count initial default state -> first actual selection as a switch.
r4.count_initial_switch = true;

% Parameter scan candidates for quick diagnostics.
r4.scan = struct();
r4.scan.tau_low_ratio_grid = [0.30 0.35 0.40 0.45 0.50];
r4.scan.tau_high_ratio_grid = [0.45 0.50 0.55 0.60 0.65];
end
