function test_engine_inversion_opend_vs_legacy_stage05_smallset()
startup;

ctx = build_engine_test_context();
profile = make_profile_MB_nominal_validation_stage05();
trajs_in = ctx.traj_case;

grid_table = evaluate_design_grid_opend(profile.design_pool.rows, trajs_in, profile.gamma_eff_scalar, ctx.cfg);

for k = 1:height(grid_table)
    legacy_res = evaluate_single_layer_walker_stage05( ...
        profile.design_pool.rows(k), trajs_in, profile.gamma_eff_scalar, ctx.cfg, [], []);

    assert(abs(grid_table.pass_ratio(k) - legacy_res.pass_ratio) < 1e-12, 'pass_ratio mismatch.');
    assert(grid_table.feasible_flag(k) == legacy_res.feasible_flag, 'feasible_flag mismatch.');
    assert(abs(grid_table.joint_margin(k) - legacy_res.D_G_min) < 1e-9, 'joint_margin mismatch.');
    assert(abs(grid_table.DG_rob(k) - legacy_res.D_G_min) < 1e-9, 'DG_rob mismatch.');
end

disp('test_engine_inversion_opend_vs_legacy_stage05_smallset passed.');
end
