function test_engine_inversion_closedd_vs_legacy_stage09_smallset()
startup;

ctx = build_engine_test_context();
profile = make_ch5_minimal_profile();
trajs_in = ctx.heading_family;

grid_table = evaluate_design_grid_closedd(profile.design_rows, trajs_in, ctx.gamma_info.gamma_req, ctx.cfg);

for k = 1:height(grid_table)
    legacy_res = evaluate_single_layer_walker_stage09( ...
        profile.design_rows(k), trajs_in, ctx.gamma_info.gamma_req, ctx.cfg, []);

    assert(abs(grid_table.pass_ratio(k) - legacy_res.pass_ratio) < 1e-12, 'pass_ratio mismatch.');
    assert(grid_table.feasible_flag(k) == legacy_res.feasible_flag, 'feasible_flag mismatch.');
    assert(abs(grid_table.joint_margin(k) - legacy_res.joint_margin) < 1e-9, 'joint_margin mismatch.');
    assert(abs(grid_table.DG_rob(k) - legacy_res.DG_rob) < 1e-9, 'DG_rob mismatch.');
    assert(abs(grid_table.DA_rob(k) - legacy_res.DA_rob) < 1e-9, 'DA_rob mismatch.');
    assert(abs(grid_table.DT_rob(k) - legacy_res.DT_rob) < 1e-9, 'DT_rob mismatch.');
end

disp('test_engine_inversion_closedd_vs_legacy_stage09_smallset passed.');
end
