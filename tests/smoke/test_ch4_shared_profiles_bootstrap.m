function test_ch4_shared_profiles_bootstrap()
startup;

tp = make_ch4_task_profile();
gp = make_ch4_design_grid_profile();
ep = make_ch4_export_profile();

assert(isfield(tp, 'nominal'), 'Missing nominal task profile.');
assert(isfield(tp, 'heading_minimal'), 'Missing heading_minimal task profile.');
assert(isfield(gp, 'bootstrap'), 'Missing bootstrap grid profile.');
assert(isfield(gp, 'validation_stage05'), 'Missing validation_stage05 grid profile.');
assert(isfield(gp, 'validation_stage06'), 'Missing validation_stage06 grid profile.');
assert(isfield(ep, 'mb'), 'Missing MB export profile.');
assert(isfield(ep, 'validation'), 'Missing validation export profile.');

assert(numel(gp.bootstrap.rows) == 3, 'Expected 3 bootstrap design rows.');
assert(numel(gp.validation_stage05.rows) == 3, 'Expected 3 stage05 validation rows.');
assert(numel(gp.validation_stage06.rows) == 3, 'Expected 3 stage06 validation rows.');

disp('test_ch4_shared_profiles_bootstrap passed.');
end
