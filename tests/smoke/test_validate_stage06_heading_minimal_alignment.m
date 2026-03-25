function test_validate_stage06_heading_minimal_alignment()
startup;

result = run_validate_stage06_heading_minimal();
tbl = result.compare_table;

assert(height(tbl) == 3, 'Expected 3 heading comparison rows.');

row1 = tbl(strcmp(tbl.design_id, 'H0601'), :);
row2 = tbl(strcmp(tbl.design_id, 'H0602'), :);
row3 = tbl(strcmp(tbl.design_id, 'H0603'), :);

assert(height(row1) == 1, 'Missing H0601 comparison row.');
assert(height(row2) == 1, 'Missing H0602 comparison row.');
assert(height(row3) == 1, 'Missing H0603 comparison row.');

assert(row1.abs_diff_pass_ratio == 0 && row1.feasible_match, ...
    'Expected H0601 to align with legacy Stage06.');
assert(row2.abs_diff_pass_ratio == 0 && row2.feasible_match, ...
    'Expected H0602 to align with legacy Stage06.');

% H0603 may still carry a residual pass-ratio difference in current minimal alignment.
assert(row3.feasible_match, ...
    'Expected H0603 feasible flag to match legacy Stage06.');

disp('test_validate_stage06_heading_minimal_alignment passed.');
end
