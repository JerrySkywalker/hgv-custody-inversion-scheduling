function target_template = make_default_target_template()
%MAKE_DEFAULT_TARGET_TEMPLATE Build default target dynamics template.

target_template = struct();

target_template.dynamics = struct();
target_template.dynamics.t0_s = 0;
target_template.dynamics.tmax_s = 200;
target_template.dynamics.ts_s = 1;

target_template.dynamics.mass0_kg = 907.185;
target_template.dynamics.s_ref_m2 = 0.292;
target_template.dynamics.cd = 0.6;
target_template.dynamics.cl = 0.0;

target_template.dynamics.v0_mps = 6000;
target_template.dynamics.h0_m = 30000;
target_template.dynamics.theta0_deg = -5;
target_template.dynamics.sigma0_deg = 0;

target_template.control = struct();
target_template.control.mode = 'ballistic';
target_template.control.alpha_cmd_deg = 15.0;
target_template.control.bank_cmd_deg = 0.0;
target_template.control.alpha_nominal_deg = 15.0;
target_template.control.bank_nominal_deg = 0.0;
target_template.control.alpha_heading_deg = 15.0;
target_template.control.bank_heading_deg = 0.0;
target_template.control.alpha_c1_deg = 15.0;
target_template.control.bank_c1_deg = 0.0;
target_template.control.alpha_c2_deg = 15.0;
target_template.control.bank_c2_deg = 0.0;
target_template.control.use_heading_offset_as_bank_seed = false;
target_template.control.heading_offset_bank_gain_deg_per_deg = 0.0;

target_template.constraints = struct();
target_template.constraints.h_min_m = 0;
target_template.constraints.h_max_m = 1e6;
target_template.constraints.v_min_mps = 0;
target_template.constraints.v_max_mps = 1e5;
target_template.constraints.capture_radius_km = 50;
target_template.constraints.enable_task_capture_event = false;
target_template.constraints.enable_landing_event = true;

target_template.reference = struct();
target_template.reference.phi_ref_deg = 0;
target_template.reference.lambda_ref_deg = 0;
target_template.reference.phi0_deg = 0;
target_template.reference.lambda0_deg = 0;

target_template.planet = struct();
target_template.planet.re_m = 6378137;
end
