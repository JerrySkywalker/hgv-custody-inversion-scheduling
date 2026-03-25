function result = run_MB_nominal_small_formal_boundary_summary()
startup;

r_nom = run_MB_nominal_small_formal_master();
boundary_result = small_formal_boundary_summary_service(r_nom.truth_result);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_summary = artifact_service(boundary_result.summary_table, output_dir, 'mb_nominal_small_formal_boundary_summary');
artifact_min = artifact_service(boundary_result.minimum_feasible_table, output_dir, 'mb_nominal_small_formal_minimum_feasible');
artifact_critical = artifact_service(boundary_result.critical_boundary_table, output_dir, 'mb_nominal_small_formal_critical_boundary');
artifact_failed = artifact_service(boundary_result.failed_table, output_dir, 'mb_nominal_small_formal_failed_set');
artifact_saturated = artifact_service(boundary_result.saturated_table, output_dir, 'mb_nominal_small_formal_saturated_set');

manifest = make_artifact_manifest( ...
    'mb_nominal_small_formal_boundary_summary', ...
    {artifact_summary, artifact_min, artifact_critical, artifact_failed, artifact_saturated});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_nominal_small_formal_boundary_summary');

result = struct();
result.master_result = r_nom;
result.boundary_result = boundary_result;
result.artifact_summary = artifact_summary;
result.artifact_min = artifact_min;
result.artifact_critical = artifact_critical;
result.artifact_failed = artifact_failed;
result.artifact_saturated = artifact_saturated;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[experiment] MB nominal small-formal boundary summary completed.');
disp(boundary_result.summary_table);
disp(boundary_result.minimum_feasible_table(:, {'design_id','P','T','Ns','joint_margin','is_feasible'}));
disp(boundary_result.critical_boundary_table(:, {'design_id','P','T','Ns','joint_margin','is_feasible'}));
end
