function test_framework_boundary_summary_consistency()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;
boundary_result = summarize_boundary(tbl);

if any(tbl.is_feasible)
    min_Ns = min(tbl.Ns(tbl.is_feasible));
    assert(all(boundary_result.minimum_feasible_table.Ns == min_Ns), 'Minimum feasible Ns mismatch.');
else
    assert(isempty(boundary_result.minimum_feasible_table), 'Expected empty minimum feasible table.');
end

assert(height(boundary_result.failed_table) == sum(~tbl.is_feasible), 'Failed-set count mismatch.');
assert(height(boundary_result.saturated_table) == sum(tbl.joint_margin >= 2), 'Saturated-set count mismatch.');

disp('test_framework_boundary_summary_consistency passed.');
end
