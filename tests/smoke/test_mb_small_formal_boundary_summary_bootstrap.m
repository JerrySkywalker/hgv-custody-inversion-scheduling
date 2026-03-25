function test_mb_small_formal_boundary_summary_bootstrap()
startup;

r_nom = run_MB_nominal_small_formal_boundary_summary();
r_head = run_MB_heading_small_formal_boundary_summary();

assert(height(r_nom.boundary_result.summary_table) == 1, 'Expected 1 nominal boundary summary row.');
assert(height(r_head.boundary_result.summary_table) == 1, 'Expected 1 heading boundary summary row.');

assert(isfield(r_nom.boundary_result, 'minimum_feasible_table'), 'Missing nominal minimum_feasible_table.');
assert(isfield(r_nom.boundary_result, 'critical_boundary_table'), 'Missing nominal critical_boundary_table.');
assert(isfield(r_nom.boundary_result, 'failed_table'), 'Missing nominal failed_table.');
assert(isfield(r_nom.boundary_result, 'saturated_table'), 'Missing nominal saturated_table.');

assert(isfield(r_head.boundary_result, 'minimum_feasible_table'), 'Missing heading minimum_feasible_table.');
assert(isfield(r_head.boundary_result, 'critical_boundary_table'), 'Missing heading critical_boundary_table.');
assert(isfield(r_head.boundary_result, 'failed_table'), 'Missing heading failed_table.');
assert(isfield(r_head.boundary_result, 'saturated_table'), 'Missing heading saturated_table.');

assert(isfile(r_nom.manifest_paths.mat_path), 'Missing nominal boundary summary manifest MAT.');
assert(isfile(r_nom.manifest_paths.txt_path), 'Missing nominal boundary summary manifest TXT.');
assert(isfile(r_head.manifest_paths.mat_path), 'Missing heading boundary summary manifest MAT.');
assert(isfile(r_head.manifest_paths.txt_path), 'Missing heading boundary summary manifest TXT.');

disp('test_mb_small_formal_boundary_summary_bootstrap passed.');
end
