function result = run_MB_small_formal_compare_master()
startup;

r_nom = run_MB_nominal_small_formal_master();
r_head = run_MB_heading_small_formal_master();

compare_result = small_formal_compare_service(r_nom, r_head);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_summary = artifact_service(compare_result.summary_table, output_dir, 'mb_small_formal_summary');
artifact_compare = artifact_service(compare_result.compare_table, output_dir, 'mb_small_formal_compare');

manifest = make_artifact_manifest( ...
    'mb_small_formal_compare_master_run', ...
    {artifact_summary, artifact_compare});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_small_formal_compare_master_run');

result = struct();
result.nominal_result = r_nom;
result.heading_result = r_head;
result.compare_result = compare_result;
result.artifact_summary = artifact_summary;
result.artifact_compare = artifact_compare;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[experiment] MB small-formal compare master run completed.');
disp(compare_result.summary_table);
disp(compare_result.compare_table(:, {'P','T','Ns','nominal_pass_ratio','heading_pass_ratio','abs_diff_pass_ratio','feasible_match','joint_margin_diff'}));
end
