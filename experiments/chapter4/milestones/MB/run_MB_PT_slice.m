function slice_result = run_MB_PT_slice()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

slice_spec = struct();
slice_spec.mode = 'PT';
slice_spec.feasible_only = true;
slice_spec.sort_by = 'Ns_asc';

slice_result = slice_service(out.truth_result, slice_spec);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');
artifact = artifact_service(slice_result.table, output_dir, 'mb_pt_slice');

slice_result.artifact = artifact;

disp('[experiment] MB PT slice completed.');
disp(slice_result.table);
disp(artifact);
end
