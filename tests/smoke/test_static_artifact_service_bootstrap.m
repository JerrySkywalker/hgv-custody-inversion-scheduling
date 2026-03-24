function test_static_artifact_service_bootstrap()
startup;

slice_result = run_MB_PT_slice();
assert(isfield(slice_result, 'artifact'), 'Missing slice artifact.');
assert(isfile(slice_result.artifact.file_path), 'Slice artifact file was not created.');

comparison_result = run_MB_family_compare();
assert(isfield(comparison_result, 'artifact'), 'Missing comparison artifact.');
assert(isfile(comparison_result.artifact.file_path), 'Comparison artifact file was not created.');

disp('test_static_artifact_service_bootstrap passed.');
end
