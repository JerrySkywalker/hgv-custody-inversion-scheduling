function test_mb_small_formal_family_compare_bootstrap()
startup;

result = run_MB_small_formal_family_compare();

assert(height(result.summary_table) == 2, 'Expected 2 family summary rows.');
assert(height(result.compare_table) == 16, 'Expected 16 family compare rows.');

assert(all(ismember({'family_name','design_count','feasible_count','feasible_ratio','min_Ns','best_design_id'}, ...
    result.summary_table.Properties.VariableNames)), ...
    'Missing expected family summary variables.');

assert(all(ismember({'P','T','Ns','nominal_pass_ratio','heading_pass_ratio', ...
    'abs_diff_pass_ratio','feasible_match','joint_margin_diff'}, ...
    result.compare_table.Properties.VariableNames)), ...
    'Missing expected family compare variables.');

assert(isfile(result.manifest_paths.mat_path), 'Missing family-compare manifest MAT.');
assert(isfile(result.manifest_paths.txt_path), 'Missing family-compare manifest TXT.');

disp('test_mb_small_formal_family_compare_bootstrap passed.');
end
