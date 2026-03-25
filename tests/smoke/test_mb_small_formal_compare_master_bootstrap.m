function test_mb_small_formal_compare_master_bootstrap()
startup;

result = run_MB_small_formal_compare_master();

summary_tbl = result.compare_result.summary_table;
compare_tbl = result.compare_result.compare_table;

assert(height(summary_tbl) == 2, 'Expected 2 summary rows for nominal and heading.');
assert(height(compare_tbl) == 16, 'Expected 16 compare rows for small-formal grid.');

assert(all(ismember({'family_name','design_count','feasible_count','feasible_ratio','min_Ns','best_design_id'}, ...
    summary_tbl.Properties.VariableNames)), ...
    'Missing expected summary table variables.');

assert(all(ismember({'P','T','Ns','nominal_pass_ratio','heading_pass_ratio','abs_diff_pass_ratio','feasible_match','joint_margin_diff'}, ...
    compare_tbl.Properties.VariableNames)), ...
    'Missing expected compare table variables.');

assert(isfile(result.manifest_paths.mat_path), 'Missing small-formal compare manifest MAT.');
assert(isfile(result.manifest_paths.txt_path), 'Missing small-formal compare manifest TXT.');

disp('test_mb_small_formal_compare_master_bootstrap passed.');
end
