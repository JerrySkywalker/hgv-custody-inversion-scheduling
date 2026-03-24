function test_static_manager_heading_bootstrap()
startup;

profile = make_profile_MB_heading();
mgr = create_static_evaluation_manager(profile);
out = mgr.run();

assert(isstruct(out), 'Output must be a struct.');
assert(strcmp(out.task_family.name, 'heading'), 'Task family should be heading.');

assert(isfield(out, 'truth_result'), 'Missing truth_result.');
assert(isfield(out.truth_result, 'table'), 'Missing truth table.');

tbl = out.truth_result.table;
assert(height(tbl) >= 1, 'Expected at least one truth row.');

assert(all(ismember({'design_id','Ns','joint_margin','is_feasible','fail_reason'}, ...
    tbl.Properties.VariableNames)), ...
    'Missing expected heading truth table variables.');

disp('test_static_manager_heading_bootstrap passed.');
end
