function test_static_nominal_master_run_bootstrap()
startup;

result = run_MB_nominal();

assert(isfield(result, 'out'), 'Missing out.');
assert(isfield(result, 'pt_slice_result'), 'Missing pt_slice_result.');
assert(isfield(result, 'minimum_result'), 'Missing minimum_result.');

assert(isfield(result, 'artifact_truth'), 'Missing artifact_truth.');
assert(isfield(result, 'artifact_pt_slice'), 'Missing artifact_pt_slice.');
assert(isfield(result, 'artifact_minimum'), 'Missing artifact_minimum.');
assert(isfield(result, 'artifact_near_optimal'), 'Missing artifact_near_optimal.');

assert(isfield(result, 'manifest'), 'Missing manifest.');
assert(isfield(result, 'manifest_paths'), 'Missing manifest_paths.');

assert(isfile(result.artifact_truth.file_path), 'Truth table artifact missing.');
assert(isfile(result.artifact_pt_slice.file_path), 'PT slice artifact missing.');
assert(isfile(result.artifact_minimum.file_path), 'Minimum artifact missing.');
assert(isfile(result.artifact_near_optimal.file_path), 'Near-optimal artifact missing.');

assert(isfile(result.manifest_paths.mat_path), 'Manifest MAT missing.');
assert(isfile(result.manifest_paths.txt_path), 'Manifest TXT missing.');

disp('test_static_nominal_master_run_bootstrap passed.');
end
