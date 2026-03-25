function diagnose_result = run_diagnose_heading_stage06_case_list()
startup;

profile = make_profile_MB_heading_validation_stage06();
cfg = config_service(profile);
design_pool = design_pool_service(cfg);
task_family = task_family_service(cfg);

design_rows = design_pool.design_table;
idx = find(strcmp({design_rows.design_id}, 'H0603'), 1);
assert(~isempty(idx), 'Expected H0603 in heading validation design pool.');
design_point = design_rows(idx);

case_table = task_family.case_table;
n_cases = height(case_table);
assert(n_cases >= 1, 'Expected non-empty heading case table.');

diag_rows = repmat(struct(), n_cases, 1);

for k = 1:n_cases
    task_family_k = task_family;
    task_family_k.case_table = case_table(k, :);
    task_family_k.trajs_in = task_family.trajs_in(k);

    eval_row = adapter_design_eval_legacy(design_point, task_family_k, profile);

    diag_rows(k).design_id = string(design_point.design_id);
    diag_rows(k).case_id = string(case_table.case_id(k));

    if ismember('family', case_table.Properties.VariableNames)
        diag_rows(k).family = string(case_table.family(k));
    else
        diag_rows(k).family = "";
    end

    if ismember('subfamily', case_table.Properties.VariableNames)
        diag_rows(k).subfamily = string(case_table.subfamily(k));
    else
        diag_rows(k).subfamily = "";
    end

    if ismember('heading_offset_deg', case_table.Properties.VariableNames)
        diag_rows(k).heading_offset_deg = case_table.heading_offset_deg(k);
    else
        diag_rows(k).heading_offset_deg = NaN;
    end

    diag_rows(k).gamma_eff_scalar = eval_row.gamma_eff_scalar;
    diag_rows(k).gamma_source = string(eval_row.gamma_source);
    diag_rows(k).Tw_s = eval_row.Tw_s;

    diag_rows(k).DG_rob = eval_row.raw_DG_rob;
    diag_rows(k).DA_rob = eval_row.raw_DA_rob;
    diag_rows(k).DT_rob = eval_row.raw_DT_rob;
    diag_rows(k).joint_margin = eval_row.raw_joint_margin;

    diag_rows(k).pass_ratio = eval_row.pass_ratio;
    diag_rows(k).is_feasible = logical(eval_row.raw_feasible_flag);
    diag_rows(k).rank_score = eval_row.rank_score;

    diag_rows(k).worst_case_id_DG = string(eval_row.worst_case_id_DG);
    diag_rows(k).worst_case_id_DA = string(eval_row.worst_case_id_DA);
    diag_rows(k).worst_case_id_DT = string(eval_row.worst_case_id_DT);

    diag_rows(k).n_case_total = eval_row.n_case_total;
    diag_rows(k).n_case_evaluated = eval_row.n_case_evaluated;
end

diag_table = struct2table(diag_rows);

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');
artifact = artifact_service(diag_table, output_dir, 'diagnose_stage06_heading_case_list');
manifest = make_artifact_manifest('diagnose_heading_stage06_case_list', artifact);
manifest_paths = save_artifact_manifest(manifest, output_dir, 'diagnose_stage06_heading_case_list');

diagnose_result = struct();
diagnose_result.design_point = design_point;
diagnose_result.case_table = case_table;
diagnose_result.diag_table = diag_table;
diagnose_result.artifact = artifact;
diagnose_result.manifest = manifest;
diagnose_result.manifest_paths = manifest_paths;

disp('[diagnose] Heading Stage06 case-list diagnosis completed.');
disp(diag_table(:, {'design_id','case_id','heading_offset_deg','DG_rob','pass_ratio','is_feasible','joint_margin'}));
end
