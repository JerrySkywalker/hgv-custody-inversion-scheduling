function minimum_result = run_MB_minimum()
startup;

mgr = create_static_evaluation_manager(make_profile_MB_nominal());
out = mgr.run();

minimum_result = out.minimum_solution_result;

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_solution = artifact_service( ...
    minimum_result.solution_table, ...
    output_dir, ...
    'mb_minimum_solution');

artifact_near_optimal = artifact_service( ...
    minimum_result.near_optimal_table, ...
    output_dir, ...
    'mb_near_optimal_solution');

manifest = make_artifact_manifest( ...
    'MB_minimum_solution', ...
    {artifact_solution, artifact_near_optimal});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_minimum_solution');

minimum_result.artifact_solution = artifact_solution;
minimum_result.artifact_near_optimal = artifact_near_optimal;
minimum_result.manifest = manifest;
minimum_result.manifest_paths = manifest_paths;

disp('[experiment] MB minimum solution extraction completed.');
disp(minimum_result.solution_table);
disp(minimum_result.near_optimal_table);
disp(manifest_paths);
end
