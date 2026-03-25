function compare_result = ch4_small_formal_compare_service(nominal_result, heading_result)
tbl_nom = nominal_result.truth_result.table;
tbl_head = heading_result.truth_result.table;

summary_nom = build_family_summary('nominal', tbl_nom);
summary_head = build_family_summary('heading', tbl_head);

compare_tbl = compare_truth_tables( ...
    tbl_nom, tbl_head, {'P','T','h_km','i_deg','Ns'}, struct( ...
        'metric_columns', {{'design_id','pass_ratio','is_feasible','joint_margin'}}, ...
        'left_prefix', 'nominal', ...
        'right_prefix', 'heading'));

compare_tbl.abs_diff_pass_ratio = abs(compare_tbl.nominal_pass_ratio - compare_tbl.heading_pass_ratio);
compare_tbl.feasible_match = compare_tbl.nominal_is_feasible == compare_tbl.heading_is_feasible;
compare_tbl.joint_margin_diff = compare_tbl.nominal_joint_margin - compare_tbl.heading_joint_margin;

summary_table = struct2table([summary_nom; summary_head]);

compare_result = struct();
compare_result.summary_table = summary_table;
compare_result.compare_table = compare_tbl;
compare_result.summary_nominal = summary_nom;
compare_result.summary_heading = summary_head;
end

function summary = build_family_summary(family_name, tbl)
boundary_result = summarize_boundary(tbl);
if ismember('is_feasible', tbl.Properties.VariableNames)
    feasible_mask = tbl.is_feasible;
else
    feasible_mask = logical(tbl.feasible_flag);
end

summary = struct();
summary.family_name = string(family_name);
summary.design_count = height(tbl);
summary.feasible_count = sum(feasible_mask);
summary.feasible_ratio = mean(double(feasible_mask));

if isempty(boundary_result.minimum_feasible_table)
    summary.min_Ns = NaN;
    summary.min_joint_margin = NaN;
    summary.max_joint_margin = max(tbl.joint_margin);
    summary.best_design_id = "";
else
    summary.min_Ns = min(boundary_result.minimum_feasible_table.Ns);
    summary.min_joint_margin = min(boundary_result.minimum_feasible_table.joint_margin);
    summary.max_joint_margin = max(tbl.joint_margin);

    candidate_tbl = boundary_result.minimum_feasible_table;
    [~, idx_best] = max(candidate_tbl.joint_margin);
    summary.best_design_id = string(candidate_tbl.design_id(idx_best));
end
end
