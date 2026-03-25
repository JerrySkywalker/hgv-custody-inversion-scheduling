function demo_out = run_engine_target_resource_bootstrap_demo()
startup;

cfg = default_params();

casebank = build_casebank_nominal(cfg);
nominal_case = casebank.nominal(1);
nominal_traj = propagate_target_case(nominal_case, cfg);
heading_offsets_deg = [0, -30, 30];
trajs_in = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

design_row = struct( ...
    'h_km', cfg.stage03.h_km, ...
    'i_deg', cfg.stage03.i_deg, ...
    'P', cfg.stage03.P, ...
    'T', cfg.stage03.T, ...
    'F', cfg.stage03.F);

walker = build_single_layer_walker(design_row, cfg);
satbank = propagate_constellation(walker, nominal_traj.t_s, cfg);

demo_out = struct();
demo_out.nominal_case_id = nominal_case.case_id;
demo_out.heading_case_ids = arrayfun(@(s) string(s.case.case_id), trajs_in, 'UniformOutput', true);
demo_out.heading_offsets_deg = heading_offsets_deg(:);
demo_out.walker = walker;
demo_out.satbank_size = size(satbank.r_eci_km);
demo_out.n_heading_cases = numel(trajs_in);
demo_out.n_sats = satbank.Ns;
demo_out.n_time = numel(satbank.t_s);

fprintf('Engine bootstrap demo completed.\n');
fprintf('Nominal case: %s\n', nominal_case.case_id);
fprintf('Heading family size: %d\n', numel(trajs_in));
fprintf('Walker satellites: %d\n', satbank.Ns);
fprintf('Common time steps: %d\n', numel(satbank.t_s));
end
