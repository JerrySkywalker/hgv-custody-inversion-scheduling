function compare_result = run_MB_compare_master()
startup;

nominal_result = run_MB_nominal();
heading_result = run_MB_heading();

family_results = {nominal_result.out, heading_result.out};
comparison_result = task_family_comparison_service(family_results);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');
artifact = artifact_service( ...
    comparison_result.table, ...
    output_dir, ...
    'mb_compare_master_family_comparison');

manifest = make_artifact_manifest( ...
    'MB_compare_master', ...
    {artifact});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_compare_master');

compare_result = struct();
compare_result.nominal_result = nominal_result;
compare_result.heading_result = heading_result;
compare_result.comparison_result = comparison_result;
compare_result.artifact = artifact;
compare_result.manifest = manifest;
compare_result.manifest_paths = manifest_paths;

disp('[experiment] MB compare master run completed.');
disp(comparison_result.table);
disp(manifest_paths);
end
