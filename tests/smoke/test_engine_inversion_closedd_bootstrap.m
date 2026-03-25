function test_engine_inversion_closedd_bootstrap()
startup;

cfg = default_params();
profile = make_profile_MB_nominal_validation_stage05();
heading_offsets_deg = [0, -30, 30];

casebank = build_casebank_nominal(cfg);
nominal_case = casebank.nominal(1);
nominal_traj = propagate_target_case(nominal_case, cfg);
trajs_in = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

grid_table = evaluate_design_grid_closedd(profile.design_pool.rows, trajs_in, profile.gamma_eff_scalar, cfg);

assert(height(grid_table) == numel(profile.design_pool.rows), 'ClosedD grid row count mismatch.');

eval_ctx = build_stage09_eval_context(trajs_in, cfg, profile.gamma_eff_scalar);

for k = 1:height(grid_table)
    design_id = string(grid_table.design_id(k));
    row_engine = grid_table(k, :);

    legacy_row = profile.design_pool.rows(k);
    legacy_res = evaluate_single_layer_walker_stage09(legacy_row, trajs_in, profile.gamma_eff_scalar, cfg, eval_ctx);

    assert(abs(row_engine.DG_rob - legacy_res.DG_rob) < 1e-9, ...
        'ClosedD DG_rob mismatch for %s.', design_id);
    assert(abs(row_engine.DA_rob - legacy_res.DA_rob) < 1e-9, ...
        'ClosedD DA_rob mismatch for %s.', design_id);
    assert(abs(row_engine.DT_rob - legacy_res.DT_rob) < 1e-9, ...
        'ClosedD DT_rob mismatch for %s.', design_id);
    assert(abs(row_engine.joint_margin - legacy_res.joint_margin) < 1e-9, ...
        'ClosedD joint_margin mismatch for %s.', design_id);
    assert(abs(row_engine.pass_ratio - legacy_res.pass_ratio) < 1e-12, ...
        'ClosedD pass_ratio mismatch for %s.', design_id);
    assert(row_engine.feasible_flag == legacy_res.feasible_flag, ...
        'ClosedD feasible flag mismatch for %s.', design_id);
end

disp('test_engine_inversion_closedd_bootstrap passed.');
end
