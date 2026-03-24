function test_static_artifact_manifest_bootstrap()
startup;

slice_result = run_MB_PT_slice();
assert(isfield(slice_result, 'manifest'), 'Missing slice manifest.');
assert(isfield(slice_result.manifest, 'artifact_count'), 'Missing manifest artifact_count.');
assert(slice_result.manifest.artifact_count == 1, 'Expected one artifact in slice manifest.');

comparison_result = run_MB_family_compare();
assert(isfield(comparison_result, 'manifest'), 'Missing comparison manifest.');
assert(isfield(comparison_result.manifest, 'artifact_count'), 'Missing manifest artifact_count.');
assert(comparison_result.manifest.artifact_count == 1, 'Expected one artifact in comparison manifest.');

disp('test_static_artifact_manifest_bootstrap passed.');
end
