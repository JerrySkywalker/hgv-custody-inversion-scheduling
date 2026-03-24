function test_validate_against_stage05_06_bootstrap()
startup;

result = run_validate_against_stage05_06();

assert(isfield(result, 'nominal_compare'), 'Missing nominal_compare.');
assert(isfield(result, 'heading_compare'), 'Missing heading_compare.');
assert(isfield(result, 'artifact_nominal'), 'Missing artifact_nominal.');
assert(isfield(result, 'artifact_heading'), 'Missing artifact_heading.');
assert(isfield(result, 'manifest_paths'), 'Missing manifest_paths.');

assert(height(result.nominal_compare) >= 1, 'Expected nominal comparison rows.');
assert(height(result.heading_compare) >= 1, 'Expected heading comparison rows.');

assert(all(ismember({'new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}, ...
    result.nominal_compare.Properties.VariableNames)), ...
    'Missing expected nominal comparison variables.');

assert(all(ismember({'new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}, ...
    result.heading_compare.Properties.VariableNames)), ...
    'Missing expected heading comparison variables.');

assert(isfile(result.artifact_nominal.file_path), 'Nominal validation CSV missing.');
assert(isfile(result.artifact_heading.file_path), 'Heading validation CSV missing.');
assert(isfile(result.manifest_paths.mat_path), 'Validation manifest MAT missing.');
assert(isfile(result.manifest_paths.txt_path), 'Validation manifest TXT missing.');

disp('test_validate_against_stage05_06_bootstrap passed.');
end
