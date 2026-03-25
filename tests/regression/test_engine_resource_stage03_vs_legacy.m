function test_engine_resource_stage03_vs_legacy()
startup;

ctx = build_engine_test_context();
walker_engine = build_single_layer_walker(ctx.design_row, ctx.cfg);
cfg_legacy = ctx.cfg;
cfg_legacy.stage03.h_km = ctx.design_row.h_km;
cfg_legacy.stage03.i_deg = ctx.design_row.i_deg;
cfg_legacy.stage03.P = ctx.design_row.P;
cfg_legacy.stage03.T = ctx.design_row.T;
cfg_legacy.stage03.F = ctx.design_row.F;
walker_legacy = build_single_layer_walker_stage03(cfg_legacy);
satbank_engine = propagate_constellation(walker_engine, ctx.nominal_traj.t_s, ctx.cfg);
satbank_legacy = propagate_constellation_stage03(walker_legacy, ctx.nominal_traj.t_s);

assert(walker_engine.Ns == walker_legacy.Ns, 'Walker satellite count mismatch.');
assert(all(size(satbank_engine.r_eci_km) == size(satbank_legacy.r_eci_km)), 'Constellation size mismatch.');
assert(max(abs(satbank_engine.r_eci_km(:) - satbank_legacy.r_eci_km(:))) < 1e-9, ...
    'Constellation propagation mismatch.');

disp('test_engine_resource_stage03_vs_legacy passed.');
end
