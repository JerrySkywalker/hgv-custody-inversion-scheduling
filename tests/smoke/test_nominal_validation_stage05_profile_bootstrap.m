function test_nominal_validation_stage05_profile_bootstrap()
startup;

profile = make_profile_MB_nominal_validation_stage05();
assert(isfield(profile, 'gamma_eff_scalar'), 'Missing gamma_eff_scalar in profile.');
assert(isfield(profile, 'gamma_source'), 'Missing gamma_source in profile.');
assert(isfield(profile, 'gamma_cache_file'), 'Missing gamma_cache_file in profile.');
assert(profile.gamma_eff_scalar > 0, 'Expected positive gamma_eff_scalar.');
assert(strcmp(profile.gamma_source, 'stage04_nominal_quantile'), ...
    'Expected gamma_source to match stage04_nominal_quantile.');
assert(isfile(profile.gamma_cache_file), 'Expected gamma cache file to exist.');

result = run_MB_nominal_validation_stage05();
tbl = result.truth_result.table;

assert(height(tbl) == 3, 'Expected exactly 3 validation design rows.');
assert(all(tbl.h_km == 1000), 'Expected validation profile h_km to be 1000.');
assert(all(tbl.i_deg == 60), 'Expected validation profile i_deg to be 60.');
assert(all(tbl.gamma_eff_scalar == profile.gamma_eff_scalar), ...
    'Expected truth table gamma_eff_scalar to match profile.');
assert(all(strcmp(tbl.gamma_source, profile.gamma_source)), ...
    'Expected truth table gamma_source to match profile.');

assert(all(ismember({'design_id','h_km','i_deg','P','T','Ns','pass_ratio', ...
    'is_feasible','joint_margin','gamma_eff_scalar','gamma_source'}, ...
    tbl.Properties.VariableNames)), ...
    'Missing expected validation truth table variables.');

disp('test_nominal_validation_stage05_profile_bootstrap passed.');
end
