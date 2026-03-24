function test_static_compare_master_run_bootstrap()
startup;

result = run_MB_compare_master();

assert(isfield(result, 'nominal_result'), 'Missing nominal_result.');
assert(isfield(result, 'heading_result'), 'Missing heading_result.');
assert(isfield(result, 'comparison_result'), 'Missing comparison_result.');
assert(isfield(result, 'artifact'), 'Missing artifact.');
assert(isfield(result, 'manifest'), 'Missing manifest.');
assert(isfield(result, 'manifest_paths'), 'Missing manifest_paths.');

tbl = result.comparison_result.table;
assert(height(tbl) == 2, 'Expected two family rows in comparison table.');

assert(isfile(result.artifact.file_path), 'Comparison artifact CSV missing.');
assert(isfile(result.artifact.latest_file_path), 'Comparison latest CSV missing.');
assert(isfile(result.manifest_paths.mat_path), 'Comparison manifest MAT missing.');
assert(isfile(result.manifest_paths.txt_path), 'Comparison manifest TXT missing.');

disp('test_static_compare_master_run_bootstrap passed.');
end
