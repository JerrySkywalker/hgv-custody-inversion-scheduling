function test_framework_fixed_path_curve_consistency()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;

curve_tbl = build_fixed_path_curve(tbl, struct('mode', 'diag_PT'));
direct_tbl = sortrows(tbl(tbl.P == tbl.T, :), {'Ns','P','T'}, {'ascend','ascend','ascend'});
curve_core = curve_tbl(:, direct_tbl.Properties.VariableNames);

assert(height(curve_tbl) == height(direct_tbl), 'Fixed-path row count mismatch.');
assert(all(strcmp(curve_core.design_id, direct_tbl.design_id)), 'Fixed-path design ordering mismatch.');
assert(max(abs(curve_core.pass_ratio - direct_tbl.pass_ratio)) < 1e-12, 'Fixed-path pass_ratio mismatch.');
assert(max(abs(curve_core.joint_margin - direct_tbl.joint_margin)) < 1e-12, 'Fixed-path joint_margin mismatch.');
assert(isequal(curve_core(:, {'P','T','Ns'}), direct_tbl(:, {'P','T','Ns'})), ...
    'Fixed-path curve content mismatch.');

disp('test_framework_fixed_path_curve_consistency passed.');
end
