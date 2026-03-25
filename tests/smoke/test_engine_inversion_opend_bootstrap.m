function test_engine_inversion_opend_bootstrap()
startup;

cfg = default_params();
profile = make_profile_MB_nominal_validation_stage05();
validation_result = run_MB_nominal_validation_stage05();
validation_tbl = validation_result.truth_result.table;

casebank = build_casebank_nominal(cfg);
nominal_case = casebank.nominal(1);
nominal_traj = propagate_target_case(nominal_case, cfg);
trajs_in = struct('case', nominal_case, 'traj', nominal_traj);

grid_table = evaluate_design_grid_opend(profile.design_pool.rows, trajs_in, profile.gamma_eff_scalar, cfg);

assert(height(grid_table) == numel(profile.design_pool.rows), 'OpenD grid row count mismatch.');

for k = 1:height(grid_table)
    design_id = string(grid_table.design_id(k));
    row_engine = grid_table(k, :);
    row_validation = validation_tbl(strcmp(string(validation_tbl.design_id), design_id), :);
    assert(height(row_validation) == 1, 'Missing validation row for %s.', design_id);

    legacy_row = profile.design_pool.rows(k);
    legacy_res = evaluate_single_layer_walker_stage05(legacy_row, trajs_in, profile.gamma_eff_scalar, cfg, [], []);

    assert(abs(row_engine.pass_ratio - row_validation.pass_ratio) < 1e-12, ...
        'Validation pass_ratio mismatch for %s.', design_id);
    assert(row_engine.feasible_flag == row_validation.is_feasible, ...
        'Validation feasible flag mismatch for %s.', design_id);
    assert(abs(row_engine.joint_margin - row_validation.joint_margin) < 1e-9, ...
        'Validation joint_margin mismatch for %s.', design_id);

    assert(abs(row_engine.pass_ratio - legacy_res.pass_ratio) < 1e-12, ...
        'Legacy Stage05 pass_ratio mismatch for %s.', design_id);
    assert(row_engine.feasible_flag == legacy_res.feasible_flag, ...
        'Legacy Stage05 feasible flag mismatch for %s.', design_id);
    assert(abs(row_engine.joint_margin - legacy_res.D_G_min) < 1e-9, ...
        'Legacy Stage05 D_G mismatch for %s.', design_id);
end

disp('test_engine_inversion_opend_bootstrap passed.');
end
