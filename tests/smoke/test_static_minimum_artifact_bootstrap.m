function test_static_minimum_artifact_bootstrap()
startup;

minimum_result = run_MB_minimum();

assert(isfield(minimum_result, 'solution_table'), 'Missing solution_table.');
assert(isfield(minimum_result, 'near_optimal_table'), 'Missing near_optimal_table.');
assert(isfield(minimum_result, 'artifact_solution'), 'Missing artifact_solution.');
assert(isfield(minimum_result, 'artifact_near_optimal'), 'Missing artifact_near_optimal.');
assert(isfield(minimum_result, 'manifest'), 'Missing manifest.');
assert(isfield(minimum_result, 'manifest_paths'), 'Missing manifest_paths.');

assert(height(minimum_result.solution_table) >= 1, 'Expected at least one minimum solution row.');
assert(height(minimum_result.near_optimal_table) >= height(minimum_result.solution_table), ...
    'Expected near-optimal table to have at least as many rows as solution table.');

assert(isfile(minimum_result.artifact_solution.file_path), ...
    'Minimum solution CSV was not created.');
assert(isfile(minimum_result.artifact_solution.latest_file_path), ...
    'Minimum solution latest CSV was not created.');

assert(isfile(minimum_result.artifact_near_optimal.file_path), ...
    'Near-optimal CSV was not created.');
assert(isfile(minimum_result.artifact_near_optimal.latest_file_path), ...
    'Near-optimal latest CSV was not created.');

assert(isfile(minimum_result.manifest_paths.mat_path), ...
    'Minimum manifest MAT file was not created.');
assert(isfile(minimum_result.manifest_paths.txt_path), ...
    'Minimum manifest TXT file was not created.');

disp('test_static_minimum_artifact_bootstrap passed.');
end
