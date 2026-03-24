function comparison_result = run_MB_family_compare()
startup;

mgr_nominal = create_static_evaluation_manager(make_profile_MB_nominal());
out_nominal = mgr_nominal.run();

mgr_heading = create_static_evaluation_manager(make_profile_MB_heading());
out_heading = mgr_heading.run();

family_results = {out_nominal, out_heading};
comparison_result = task_family_comparison_service(family_results);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');
artifact = artifact_service(comparison_result.table, output_dir, 'mb_family_comparison');
manifest = make_artifact_manifest('MB_family_comparison', artifact);

comparison_result.artifact = artifact;
comparison_result.manifest = manifest;

disp('[experiment] MB family comparison completed.');
disp(comparison_result.table);
disp(artifact);
disp(manifest);
end
