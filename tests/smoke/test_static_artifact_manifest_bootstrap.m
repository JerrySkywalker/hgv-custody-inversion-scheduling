function test_static_artifact_manifest_bootstrap()
startup;

slice_result = run_MB_PT_slice();
assert(isfield(slice_result, 'manifest'), 'Missing slice manifest.');
assert(isfield(slice_result, 'manifest_paths'), 'Missing slice manifest_paths.');
assert(slice_result.manifest.artifact_count == 1, 'Expected one artifact in slice manifest.');
assert(isfile(slice_result.manifest_paths.mat_path), 'Slice manifest MAT file was not created.');
assert(isfile(slice_result.manifest_paths.txt_path), 'Slice manifest TXT file was not created.');

comparison_result = run_MB_family_compare();
assert(isfield(comparison_result, 'manifest'), 'Missing comparison manifest.');
assert(isfield(comparison_result, 'manifest_paths'), 'Missing comparison manifest_paths.');
assert(comparison_result.manifest.artifact_count == 1, 'Expected one artifact in comparison manifest.');
assert(isfile(comparison_result.manifest_paths.mat_path), 'Comparison manifest MAT file was not created.');
assert(isfile(comparison_result.manifest_paths.txt_path), 'Comparison manifest TXT file was not created.');

disp('test_static_artifact_manifest_bootstrap passed.');
end
