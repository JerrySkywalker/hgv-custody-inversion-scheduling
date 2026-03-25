function out = manual_compare_stage04_window()
cfg = default_params();

legacy_casebank = build_casebank_stage01(cfg);
case_item = legacy_casebank.nominal(1);
legacy_traj = propagate_hgv_case_stage02(case_item, cfg);
traj_case = struct('case', case_item, 'traj', legacy_traj);

legacy_walker = build_single_layer_walker_stage03(cfg);
legacy_satbank = propagate_constellation_stage03(legacy_walker, legacy_traj.t_s);
legacy_vis = compute_visibility_matrix_stage03(traj_case, legacy_satbank, cfg);
legacy_window = scan_worst_window_stage04(legacy_vis, legacy_satbank, cfg);
legacy_summary = summarize_window_case_stage04(legacy_window);

design_row = struct( ...
    'h_km', cfg.stage03.h_km, ...
    'i_deg', cfg.stage03.i_deg, ...
    'P', cfg.stage03.P, ...
    'T', cfg.stage03.T, ...
    'F', cfg.stage03.F);
engine_walker = build_single_layer_walker(design_row, cfg);
engine_satbank = propagate_constellation(engine_walker, legacy_traj.t_s, cfg);
engine_vis = compute_visibility_matrix(traj_case, engine_satbank, cfg);
engine_window = compute_window_metric(engine_vis, engine_satbank, cfg);
engine_summary = summarize_worst_window(engine_window);

out = struct();
out.lambda_worst_legacy = legacy_summary.lambda_min_worst;
out.lambda_worst_engine = engine_summary.lambda_min_worst;
out.lambda_abs_diff = abs(out.lambda_worst_legacy - out.lambda_worst_engine);

out.t0_worst_legacy = legacy_summary.t0_worst_s;
out.t0_worst_engine = engine_summary.t0_worst_s;
out.t0_abs_diff = abs(out.t0_worst_legacy - out.t0_worst_engine);
end
