function result = run_MB_small_formal_family_compare()
startup;

r_cmp = run_MB_small_formal_compare_master();

summary_table = r_cmp.compare_result.summary_table;
compare_table = r_cmp.compare_result.compare_table(:, ...
    {'P','T','Ns','nominal_pass_ratio','heading_pass_ratio', ...
     'abs_diff_pass_ratio','feasible_match','joint_margin_diff'});

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_summary = artifact_service(summary_table, output_dir, 'mb_small_formal_family_summary');
artifact_compare = artifact_service(compare_table, output_dir, 'mb_small_formal_family_compare');

manifest = make_artifact_manifest( ...
    'mb_small_formal_family_compare', ...
    {artifact_summary, artifact_compare});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_small_formal_family_compare');

result = struct();
result.summary_table = summary_table;
result.compare_table = compare_table;
result.artifact_summary = artifact_summary;
result.artifact_compare = artifact_compare;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[experiment] MB small-formal family compare completed.');
disp(summary_table);
disp(compare_table);
end
