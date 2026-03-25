function test_nominal_validation_stage05_profile_bootstrap()
startup;

result = run_MB_nominal_validation_stage05();
tbl = result.truth_result.table;

assert(height(tbl) == 3, 'Expected exactly 3 validation design rows.');
assert(all(tbl.h_km == 1000), 'Expected validation profile h_km to be 1000.');
assert(all(tbl.i_deg == 60), 'Expected validation profile i_deg to be 60.');
assert(all(ismember({'design_id','h_km','i_deg','P','T','Ns','pass_ratio','is_feasible','joint_margin'}, ...
    tbl.Properties.VariableNames)), 'Missing expected validation truth table variables.');

disp('test_nominal_validation_stage05_profile_bootstrap passed.');
end
