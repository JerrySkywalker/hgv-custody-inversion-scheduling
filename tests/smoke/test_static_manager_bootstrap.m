function test_static_manager_bootstrap()
startup;

profile = make_profile_MB_nominal();
mgr = create_static_evaluation_manager(profile);
out = mgr.run();

assert(isstruct(out), 'Output must be a struct.');
assert(isfield(out, 'design_pool'), 'Missing design_pool.');
assert(isfield(out, 'task_family'), 'Missing task_family.');
assert(isfield(out, 'truth_result'), 'Missing truth_result.');

assert(isfield(out.design_pool, 'design_count'), 'Missing design_count.');
assert(isfield(out.task_family, 'case_count'), 'Missing case_count.');
assert(isfield(out.truth_result, 'row_count'), 'Missing row_count.');

assert(out.design_pool.design_count >= 1, 'Expected at least one design.');
assert(out.task_family.case_count >= 1, 'Expected at least one task case.');
assert(out.truth_result.row_count >= 1, 'Expected at least one truth row.');

disp('test_static_manager_bootstrap passed.');
end
