function heading_run_result = run_MB_heading()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_heading());
out = mgr.run();

% PT slice
slice_spec = struct();
slice_spec.mode = 'PT';
slice_spec.feasible_only = true;
slice_spec.sort_by = 'Ns_asc';
pt_slice_result = slice_service(out.truth_result, slice_spec);

% Minimum / near-optimal
minimum_result = out.minimum_solution_result;

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_truth = artifact_service( ...
    out.truth_result.table, ...
    output_dir, ...
    'mb_heading_truth_table');

artifact_pt_slice = artifact_service( ...
    pt_slice_result.table, ...
    output_dir, ...
    'mb_heading_pt_slice');

artifact_minimum = artifact_service( ...
    minimum_result.solution_table, ...
    output_dir, ...
    'mb_heading_minimum_solution');

artifact_near_optimal = artifact_service( ...
    minimum_result.near_optimal_table, ...
    output_dir, ...
    'mb_heading_near_optimal_solution');

manifest = make_artifact_manifest( ...
    'MB_heading_master_run', ...
    {artifact_truth, artifact_pt_slice, artifact_minimum, artifact_near_optimal});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_heading_master_run');

heading_run_result = struct();
heading_run_result.out = out;
heading_run_result.pt_slice_result = pt_slice_result;
heading_run_result.minimum_result = minimum_result;

heading_run_result.artifact_truth = artifact_truth;
heading_run_result.artifact_pt_slice = artifact_pt_slice;
heading_run_result.artifact_minimum = artifact_minimum;
heading_run_result.artifact_near_optimal = artifact_near_optimal;

heading_run_result.manifest = manifest;
heading_run_result.manifest_paths = manifest_paths;

disp('[experiment] MB heading master run completed.');
disp(manifest_paths);
end
