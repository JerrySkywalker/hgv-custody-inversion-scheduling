function diagnose_result = run_diagnose_heading_stage06_case_list()
startup;

offsets = [0, -30, 30];
diag_rows = repmat(struct(), numel(offsets), 1);

for k = 1:numel(offsets)
    offset_deg = offsets(k);
    result_k = run_MB_heading_validation_stage06_singlecase(offset_deg);
    tbl_k = result_k.truth_result.table;

    row_k = tbl_k(strcmp(tbl_k.design_id, 'H0603'), :);
    assert(height(row_k) == 1, 'Expected exactly one H0603 row for offset %d.', offset_deg);

    diag_rows(k).design_id = string(row_k.design_id);
    diag_rows(k).case_id = string(sprintf('H01_%+03d', offset_deg));
    diag_rows(k).heading_offset_deg = offset_deg;

    diag_rows(k).gamma_eff_scalar = row_k.gamma_eff_scalar;
    diag_rows(k).gamma_source = string(row_k.gamma_source);
    diag_rows(k).Tw_s = row_k.Tw_s;

    diag_rows(k).DG_rob = row_k.raw_DG_rob;
    diag_rows(k).DA_rob = row_k.raw_DA_rob;
    diag_rows(k).DT_rob = row_k.raw_DT_rob;
    diag_rows(k).joint_margin = row_k.raw_joint_margin;

    diag_rows(k).pass_ratio = row_k.pass_ratio;
    diag_rows(k).is_feasible = logical(row_k.raw_feasible_flag);
    diag_rows(k).rank_score = row_k.rank_score;

    diag_rows(k).worst_case_id_DG = string(row_k.worst_case_id_DG);
    diag_rows(k).worst_case_id_DA = string(row_k.worst_case_id_DA);
    diag_rows(k).worst_case_id_DT = string(row_k.worst_case_id_DT);

    diag_rows(k).n_case_total = row_k.n_case_total;
    diag_rows(k).n_case_evaluated = row_k.n_case_evaluated;
end

diag_table = struct2table(diag_rows);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');
artifact = artifact_service(diag_table, output_dir, 'diagnose_stage06_heading_case_list');
manifest = make_artifact_manifest('diagnose_heading_stage06_case_list', artifact);
manifest_paths = save_artifact_manifest(manifest, output_dir, 'diagnose_stage06_heading_case_list');

diagnose_result = struct();
diagnose_result.offsets = offsets;
diagnose_result.diag_table = diag_table;
diagnose_result.artifact = artifact;
diagnose_result.manifest = manifest;
diagnose_result.manifest_paths = manifest_paths;

disp('[diagnose] Heading Stage06 case-list diagnosis completed.');
disp(diag_table(:, {'design_id','case_id','heading_offset_deg','DG_rob','pass_ratio','is_feasible','joint_margin'}));
end
