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

trajs_in = task_family.trajs_in;
n_cases = numel(trajs_in);
assert(n_cases >= 1, 'Expected non-empty heading trajs_in.');

diag_rows = repmat(struct(), n_cases, 1);

for k = 1:n_cases
    case_k = trajs_in(k).case;

    task_family_k = struct();
    task_family_k.name = task_family.name;
    task_family_k.mode = task_family.mode;
    task_family_k.case_count = 1;
    task_family_k.case_list = {safe_get_field(case_k, 'case_id', sprintf('case_%d', k))};
    task_family_k.trajs_in = trajs_in(k);
    task_family_k.meta = task_family.meta;

    eval_row = adapter_design_eval_legacy(design_point, task_family_k, profile);

    diag_rows(k).design_id = string(design_point.design_id);
    diag_rows(k).case_id = string(safe_get_field(case_k, 'case_id', sprintf('case_%d', k)));
    diag_rows(k).family = string(safe_get_field(case_k, 'family', ''));
    diag_rows(k).subfamily = string(safe_get_field(case_k, 'subfamily', ''));

    if isfield(case_k, 'heading_offset_deg')
        diag_rows(k).heading_offset_deg = case_k.heading_offset_deg;
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
diagnose_result.trajs_in = trajs_in;
diagnose_result.diag_table = diag_table;
diagnose_result.artifact = artifact;
diagnose_result.manifest = manifest;
diagnose_result.manifest_paths = manifest_paths;

disp('[diagnose] Heading Stage06 case-list diagnosis completed.');
disp(diag_table(:, {'design_id','case_id','heading_offset_deg','DG_rob','pass_ratio','is_feasible','joint_margin'}));
end

function value = safe_get_field(s, field_name, default_value)
if isfield(s, field_name)
    value = s.(field_name);
else
    value = default_value;
end
end
