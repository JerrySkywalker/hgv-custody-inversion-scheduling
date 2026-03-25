function test_validate_stage05_nominal_alignment()
startup;

validation_result = run_validate_against_stage05_06();
tbl = validation_result.nominal_compare;

assert(height(tbl) == 3, 'Expected 3 nominal comparison rows.');
assert(all(tbl.new_pass_ratio == tbl.legacy_pass_ratio), ...
    'Expected nominal pass_ratio to align with legacy Stage05.');
assert(all(tbl.abs_diff_pass_ratio == 0), ...
    'Expected zero pass_ratio difference for aligned nominal validation.');
assert(all(tbl.feasible_match), ...
    'Expected nominal feasible flags to match legacy Stage05.');

disp('test_validate_stage05_nominal_alignment passed.');
end
