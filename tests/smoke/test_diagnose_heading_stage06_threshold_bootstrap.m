function test_diagnose_heading_stage06_threshold_bootstrap()
startup;

result = run_diagnose_heading_stage06_threshold();

assert(isfield(result, 'diagnose_table'), 'Missing diagnose_table.');
assert(height(result.diagnose_table) == 1, 'Expected exactly one diagnosis row.');

tbl = result.diagnose_table;
assert(all(ismember({'design_id','new_gamma_eff_scalar','new_Tw_s','new_DG_rob', ...
    'legacy_gamma_req','legacy_DG_min','new_pass_ratio','legacy_pass_ratio', ...
    'feasible_match','legacy_family_scope'}, tbl.Properties.VariableNames)), ...
    'Missing expected diagnosis variables.');

assert(isfile(result.artifact.file_path), 'Diagnosis artifact CSV missing.');
assert(isfile(result.manifest_paths.mat_path), 'Diagnosis manifest MAT missing.');
assert(isfile(result.manifest_paths.txt_path), 'Diagnosis manifest TXT missing.');

disp('test_diagnose_heading_stage06_threshold_bootstrap passed.');
end
