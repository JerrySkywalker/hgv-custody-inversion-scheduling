function test_engine_inversion_opend_small_formal_sample()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;
sample_tbl = tbl(1:min(4, height(tbl)), :);
envelope_tbl = build_best_envelope(sample_tbl, 'Ns', 'pass_ratio', struct(), 'max');

assert(height(sample_tbl) >= 4, 'Expected at least 4 small-formal rows.');
assert(all(ismember({'raw_DG_rob','raw_joint_margin','raw_feasible_flag'}, sample_tbl.Properties.VariableNames)), ...
    'Missing raw OpenD diagnostic fields.');
assert(height(envelope_tbl) >= 1, 'Expected non-empty sample envelope.');

disp('test_engine_inversion_opend_small_formal_sample passed.');
end
