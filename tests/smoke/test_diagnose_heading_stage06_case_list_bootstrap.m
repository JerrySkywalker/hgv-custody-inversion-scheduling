function test_diagnose_heading_stage06_case_list_bootstrap()
startup;

result = run_diagnose_heading_stage06_case_list();

assert(isfield(result, 'diag_table'), 'Missing diag_table.');
tbl = result.diag_table;

assert(height(tbl) >= 1, 'Expected at least one case-level diagnosis row.');
assert(all(ismember({'design_id','case_id','heading_offset_deg','DG_rob', ...
    'pass_ratio','is_feasible','joint_margin'}, tbl.Properties.VariableNames)), ...
    'Missing expected case-level diagnosis variables.');

assert(isfile(result.artifact.file_path), 'Case-list diagnosis artifact CSV missing.');
assert(isfile(result.manifest_paths.mat_path), 'Case-list diagnosis manifest MAT missing.');
assert(isfile(result.manifest_paths.txt_path), 'Case-list diagnosis manifest TXT missing.');

disp('test_diagnose_heading_stage06_case_list_bootstrap passed.');
end
