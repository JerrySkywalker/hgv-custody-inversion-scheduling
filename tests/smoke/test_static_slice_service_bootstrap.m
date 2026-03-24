function test_static_slice_service_bootstrap()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

slice_result = slice_service(out.truth_result, struct('mode', 'PT'));

assert(isstruct(slice_result), 'slice_result must be a struct.');
assert(isfield(slice_result, 'table'), 'Missing slice table.');

tbl = slice_result.table;
assert(height(tbl) >= 1, 'Expected at least one slice row.');

assert(all(ismember({'design_id','P','T','Ns','joint_margin','is_feasible','fail_reason'}, ...
    tbl.Properties.VariableNames)), ...
    'Missing expected PT slice variables.');

disp('test_static_slice_service_bootstrap passed.');
end
