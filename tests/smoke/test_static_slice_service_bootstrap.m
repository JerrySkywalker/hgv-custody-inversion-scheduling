function test_static_slice_service_bootstrap()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

slice_spec = struct();
slice_spec.mode = 'PT';
slice_spec.feasible_only = true;
slice_spec.sort_by = 'Ns_asc';

slice_result = slice_service(out.truth_result, slice_spec);

assert(isstruct(slice_result), 'slice_result must be a struct.');
assert(isfield(slice_result, 'table'), 'Missing slice table.');

tbl = slice_result.table;
assert(height(tbl) >= 1, 'Expected at least one slice row.');

assert(all(ismember({'design_id','P','T','Ns','joint_margin','is_feasible','fail_reason'}, ...
    tbl.Properties.VariableNames)), ...
    'Missing expected PT slice variables.');

assert(all(tbl.is_feasible), 'Expected feasible-only slice output.');
assert(issorted(tbl.Ns), 'Expected Ns ascending sort order.');

disp('test_static_slice_service_bootstrap passed.');
end
