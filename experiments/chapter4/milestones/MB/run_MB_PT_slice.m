function slice_result = run_MB_PT_slice()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

slice_spec = struct();
slice_spec.mode = 'PT';
slice_spec.feasible_only = true;
slice_spec.sort_by = 'Ns_asc';

slice_result = slice_service(out.truth_result, slice_spec);

disp('[experiment] MB PT slice completed.');
disp(slice_result.table);
end
