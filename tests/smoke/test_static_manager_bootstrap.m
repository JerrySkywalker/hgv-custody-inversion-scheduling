function test_static_manager_bootstrap()
startup;

profile = make_profile_MB_nominal();
mgr = create_static_evaluation_manager(profile);
out = mgr.run();

assert(isstruct(out), 'Output must be a struct.');
assert(isfield(out, 'design_pool'), 'Missing design_pool.');
assert(isfield(out, 'task_family'), 'Missing task_family.');
assert(isfield(out, 'truth_result'), 'Missing truth_result.');
assert(isfield(out, 'minimum_solution_result'), 'Missing minimum_solution_result.');

assert(isfield(out.design_pool, 'design_count'), 'Missing design_count.');
assert(isfield(out.task_family, 'case_count'), 'Missing case_count.');
assert(isfield(out.truth_result, 'row_count'), 'Missing row_count.');
assert(isfield(out.truth_result, 'table'), 'Missing truth table.');

assert(out.design_pool.design_count >= 1, 'Expected at least one design.');
assert(out.task_family.case_count >= 1, 'Expected at least one task case.');
assert(out.truth_result.row_count >= 1, 'Expected at least one truth row.');

rows = out.truth_result.rows;
tbl = out.truth_result.table;

assert(numel(rows) == out.truth_result.row_count, 'rows size mismatch.');
assert(height(tbl) == out.truth_result.row_count, 'table height mismatch.');

assert(all(ismember({'geometry_margin','accuracy_margin','temporal_margin', ...
    'joint_margin','is_feasible','fail_reason'}, tbl.Properties.VariableNames)), ...
    'Missing expected truth table variables.');

ms = out.minimum_solution_result;
assert(isfield(ms, 'solution_table'), 'Missing solution_table.');
assert(isfield(ms, 'near_optimal_table'), 'Missing near_optimal_table.');
assert(isfield(ms, 'min_Ns'), 'Missing min_Ns.');
assert(isfield(ms, 'solution_count'), 'Missing solution_count.');
assert(isfield(ms, 'near_optimal_count'), 'Missing near_optimal_count.');
assert(ms.solution_count >= 1, 'Expected at least one minimum solution.');
assert(ms.near_optimal_count >= ms.solution_count, ...
    'Expected near-optimal count to be >= minimum solution count.');

disp('test_static_manager_bootstrap passed.');
end
