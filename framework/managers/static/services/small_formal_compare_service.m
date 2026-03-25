function compare_result = small_formal_compare_service(nominal_result, heading_result)
tbl_nom = nominal_result.truth_result.table;
tbl_head = heading_result.truth_result.table;

summary_nom = build_family_summary('nominal', tbl_nom);
summary_head = build_family_summary('heading', tbl_head);

nominal_tbl = tbl_nom(:, {'design_id','P','T','h_km','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});
nominal_tbl = renamevars(nominal_tbl, ...
    {'design_id','pass_ratio','is_feasible','joint_margin'}, ...
    {'nominal_design_id','nominal_pass_ratio','nominal_is_feasible','nominal_joint_margin'});

heading_tbl = tbl_head(:, {'design_id','P','T','h_km','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});
heading_tbl = renamevars(heading_tbl, ...
    {'design_id','pass_ratio','is_feasible','joint_margin'}, ...
    {'heading_design_id','heading_pass_ratio','heading_is_feasible','heading_joint_margin'});

compare_tbl = innerjoin( ...
    nominal_tbl, ...
    heading_tbl, ...
    'Keys', {'P','T','h_km','i_deg','Ns'});

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
feasible_tbl = tbl(tbl.is_feasible, :);

summary = struct();
summary.family_name = string(family_name);
summary.design_count = height(tbl);
summary.feasible_count = sum(tbl.is_feasible);
summary.feasible_ratio = mean(double(tbl.is_feasible));

if isempty(feasible_tbl)
    summary.min_Ns = NaN;
    summary.min_joint_margin = NaN;
    summary.max_joint_margin = max(tbl.joint_margin);
    summary.best_design_id = "";
else
    summary.min_Ns = min(feasible_tbl.Ns);
    summary.min_joint_margin = min(feasible_tbl.joint_margin);
    summary.max_joint_margin = max(feasible_tbl.joint_margin);

    candidate_tbl = feasible_tbl(feasible_tbl.Ns == summary.min_Ns, :);
    [~, idx_best] = max(candidate_tbl.joint_margin);
    summary.best_design_id = string(candidate_tbl.design_id(idx_best));
end
end
