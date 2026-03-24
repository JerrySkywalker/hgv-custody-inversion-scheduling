function slice_result = run_MB_PT_slice()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

slice_result = slice_service(out.truth_result, struct('mode', 'PT'));

disp('[experiment] MB PT slice completed.');
disp(slice_result.table);
end
