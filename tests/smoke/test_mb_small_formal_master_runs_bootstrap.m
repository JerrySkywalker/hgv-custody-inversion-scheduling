function test_mb_small_formal_master_runs_bootstrap()
startup;

r_nom = run_MB_nominal_small_formal_master();
r_head = run_MB_heading_small_formal_master();

assert(height(r_nom.truth_result.table) == 9, 'Expected 9 nominal small-formal truth rows.');
assert(height(r_head.truth_result.table) == 9, 'Expected 9 heading small-formal truth rows.');

assert(isfield(r_nom, 'minimum_result'), 'Missing nominal minimum_result.');
assert(isfield(r_head, 'minimum_result'), 'Missing heading minimum_result.');

assert(isfile(r_nom.manifest_paths.mat_path), 'Missing nominal small-formal manifest MAT.');
assert(isfile(r_nom.manifest_paths.txt_path), 'Missing nominal small-formal manifest TXT.');
assert(isfile(r_head.manifest_paths.mat_path), 'Missing heading small-formal manifest MAT.');
assert(isfile(r_head.manifest_paths.txt_path), 'Missing heading small-formal manifest TXT.');

disp('test_mb_small_formal_master_runs_bootstrap passed.');
end
