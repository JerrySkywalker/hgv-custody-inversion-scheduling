function reps = stage13_filter_representatives(signature_table, family_name)
%STAGE13_FILTER_REPRESENTATIVES Select lightweight representative cases per family.

rows = signature_table(strcmp(string(signature_table.family), string(family_name)), :);
reps = struct('first_failure_case', "", 'closest_feasible_case', "", 'strongest_active_case', "");
if isempty(rows)
    return;
end

infeasible_rows = rows(~rows.feasible_truth, :);
if ~isempty(infeasible_rows)
    reps.first_failure_case = string(infeasible_rows.case_tag(1));
end

feasible_rows = rows(rows.feasible_truth, :);
if ~isempty(feasible_rows)
    [~, idx] = min(abs(min([feasible_rows.D_G_worst, feasible_rows.D_A_worst, feasible_rows.D_T_worst], [], 2) - 1));
    reps.closest_feasible_case = string(feasible_rows.case_tag(idx));
end

switch string(family_name)
    case "dt_first_probe"
        target_metric = rows.D_T_worst;
    case "dg_first_probe"
        target_metric = rows.D_G_worst;
    otherwise
        target_metric = min([rows.D_G_worst, rows.D_A_worst, rows.D_T_worst], [], 2);
end
[~, idx] = min(target_metric);
reps.strongest_active_case = string(rows.case_tag(idx));
end
