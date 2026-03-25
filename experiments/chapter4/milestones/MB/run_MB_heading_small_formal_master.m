function result = run_MB_heading_small_formal_master()
startup;

out = run_MB_heading_small_formal();

truth_table = out.out.truth_result.table;
minimum_result = out.out.minimum_solution_result;

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_truth = artifact_service(truth_table, output_dir, 'mb_heading_small_formal_truth_table');
artifact_min = artifact_service(minimum_result.solution_table, output_dir, 'mb_heading_small_formal_minimum_solution');
artifact_near = artifact_service(minimum_result.near_optimal_table, output_dir, 'mb_heading_small_formal_near_optimal_solution');

manifest = make_artifact_manifest( ...
    'mb_heading_small_formal_master_run', ...
    {artifact_truth, artifact_min, artifact_near});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_heading_small_formal_master_run');

result = struct();
result.profile = out.profile;
result.out = out.out;
result.truth_result = out.out.truth_result;
result.minimum_result = minimum_result;
result.artifact_truth = artifact_truth;
result.artifact_min = artifact_min;
result.artifact_near = artifact_near;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[experiment] MB heading small-formal master run completed.');
disp(result.manifest_paths);
end
