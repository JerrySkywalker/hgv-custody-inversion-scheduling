function test_mb_small_formal_pt_slice_bootstrap()
startup;

result = run_MB_small_formal_PT_slice();

assert(height(result.nominal_slice) == 16, 'Expected 16 nominal slice rows.');
assert(height(result.heading_slice) == 16, 'Expected 16 heading slice rows.');

assert(all(ismember({'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin'}, ...
    result.nominal_slice.Properties.VariableNames)), ...
    'Missing expected nominal PT-slice variables.');

assert(all(ismember({'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin'}, ...
    result.heading_slice.Properties.VariableNames)), ...
    'Missing expected heading PT-slice variables.');

assert(isfile(result.manifest_paths.mat_path), 'Missing PT-slice manifest MAT.');
assert(isfile(result.manifest_paths.txt_path), 'Missing PT-slice manifest TXT.');

disp('test_mb_small_formal_pt_slice_bootstrap passed.');
end
