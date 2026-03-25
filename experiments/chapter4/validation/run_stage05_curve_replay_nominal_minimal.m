function result = run_stage05_curve_replay_nominal_minimal()
startup;

run_result = run_engine_opend_nominal_small_formal();
nominal_slice = slice_truth_table(run_result.truth_result.table, ...
    struct('keep_columns', {{ ...
        'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin','i_deg'}}));

replay_result = ch4_stage05_curve_replay_service(nominal_slice);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');

artifact_curve = artifact_service(replay_result.curve_table, output_dir, 'stage05_curve_replay_nominal_minimal');
artifact_summary = artifact_service(replay_result.summary_table, output_dir, 'stage05_curve_replay_nominal_minimal_summary');

manifest = make_artifact_manifest( ...
    'stage05_curve_replay_nominal_minimal', ...
    {artifact_curve, artifact_summary});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'stage05_curve_replay_nominal_minimal');

result = struct();
result.nominal_slice = nominal_slice;
result.source_run = run_result;
result.replay_result = replay_result;
result.artifact_curve = artifact_curve;
result.artifact_summary = artifact_summary;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[validation] Stage05 nominal minimal curve replay completed.');
disp(replay_result.curve_table);
disp(replay_result.summary_table);
end
