function result = run_MB_small_formal_PT_slice()
startup;

r_nom = run_MB_nominal_small_formal_master();
r_head = run_MB_heading_small_formal_master();

nominal_slice = r_nom.truth_result.table(:, ...
    {'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin'});
heading_slice = r_head.truth_result.table(:, ...
    {'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin'});

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'MB');

artifact_nom = artifact_service(nominal_slice, output_dir, 'mb_small_formal_nominal_pt_slice');
artifact_head = artifact_service(heading_slice, output_dir, 'mb_small_formal_heading_pt_slice');

manifest = make_artifact_manifest( ...
    'mb_small_formal_pt_slice', ...
    {artifact_nom, artifact_head});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'mb_small_formal_pt_slice');

result = struct();
result.nominal_slice = nominal_slice;
result.heading_slice = heading_slice;
result.artifact_nominal = artifact_nom;
result.artifact_heading = artifact_head;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[experiment] MB small-formal PT slice completed.');
disp(nominal_slice);
disp(heading_slice);
end
