function test_heading_validation_stage06_singlecase_bootstrap()
startup;

result = run_MB_heading_validation_stage06_singlecase(-30);
tbl = result.truth_result.table;

assert(height(tbl) == 3, 'Expected 3 design rows for single-case heading validation.');
assert(all(tbl.h_km == 1000), 'Expected heading single-case validation h_km to be 1000.');
assert(all(tbl.i_deg == 60), 'Expected heading single-case validation i_deg to be 60.');
assert(all(tbl.gamma_eff_scalar > 0), 'Expected positive gamma_eff_scalar.');
assert(all(tbl.Tw_s > 0), 'Expected positive Tw_s.');

disp('test_heading_validation_stage06_singlecase_bootstrap passed.');
end
