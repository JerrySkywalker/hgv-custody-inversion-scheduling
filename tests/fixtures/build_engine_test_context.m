function ctx = build_engine_test_context()
%BUILD_ENGINE_TEST_CONTEXT Build a reusable engine regression context.

startup;

cfg = default_params();
gamma_info = load_stage04_nominal_gamma_req();
cfg.stage04.Tw_s = gamma_info.Tw_s;
cfg.stage04.gamma_req = gamma_info.gamma_req;

casebank = build_casebank(cfg);
nominal_case = casebank.nominal(1);
nominal_traj = propagate_target_case(nominal_case, cfg);
traj_case = struct('case', nominal_case, 'traj', nominal_traj);

heading_offsets_deg = [0, -30, 30];
heading_family = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

design_row = struct( ...
    'design_id', 'T0001', ...
    'P', 8, ...
    'T', 8, ...
    'h_km', 1000, ...
    'i_deg', 60, ...
    'F', 0, ...
    'Ns', 64);

walker = build_single_layer_walker(design_row, cfg);
satbank = propagate_constellation(walker, nominal_traj.t_s, cfg);
vis_case = compute_visibility_matrix(traj_case, satbank, cfg);
geometry_series = compute_geometry_series(vis_case, satbank);
window_case = compute_window_metric(vis_case, satbank, cfg);

ctx = struct();
ctx.cfg = cfg;
ctx.gamma_info = gamma_info;
ctx.casebank = casebank;
ctx.nominal_case = nominal_case;
ctx.nominal_traj = nominal_traj;
ctx.traj_case = traj_case;
ctx.heading_offsets_deg = heading_offsets_deg;
ctx.heading_family = heading_family;
ctx.design_row = design_row;
ctx.walker = walker;
ctx.satbank = satbank;
ctx.vis_case = vis_case;
ctx.geometry_series = geometry_series;
ctx.window_case = window_case;
end
