function test_engine_target_stage02_nominal_vs_legacy()
startup;

ctx = build_engine_test_context();
traj_engine = propagate_target_case(ctx.nominal_case, ctx.cfg);
traj_legacy = propagate_hgv_case_stage02(ctx.nominal_case, ctx.cfg);

assert(numel(traj_engine.t_s) == numel(traj_legacy.t_s), 'Time grid length mismatch.');
assert(all(size(traj_engine.r_eci_km) == size(traj_legacy.r_eci_km)), 'ECI trajectory size mismatch.');
assert(max(abs(traj_engine.r_eci_km(:) - traj_legacy.r_eci_km(:))) < 1e-9, 'ECI trajectory mismatch.');

disp('test_engine_target_stage02_nominal_vs_legacy passed.');
end
