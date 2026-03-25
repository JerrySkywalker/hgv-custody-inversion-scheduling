function test_engine_ch4_opend_nominal_small_formal_bootstrap()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;

assert(height(tbl) == 16, 'Expected 16 engine OpenD small-formal rows.');
assert(all(ismember({'design_id', 'P', 'T', 'Ns', 'pass_ratio', 'is_feasible', 'joint_margin'}, ...
    tbl.Properties.VariableNames)), 'Missing expected truth-table columns.');
assert(height(r.envelope_result.envelope_table) >= 1, 'Expected non-empty best-pass envelope.');
assert(height(r.scatter_result.scatter_table) == height(tbl), 'Scatter table size mismatch.');
assert(all(r.fixed_path_result.curve_table.P == r.fixed_path_result.curve_table.T), ...
    'Fixed-path curve should satisfy P == T.');

disp('test_engine_ch4_opend_nominal_small_formal_bootstrap passed.');
end
