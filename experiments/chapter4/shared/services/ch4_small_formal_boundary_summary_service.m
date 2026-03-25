function boundary_result = ch4_small_formal_boundary_summary_service(truth_result)
tbl = truth_result.table;

minimum_feasible_table = table();
critical_boundary_table = table();
failed_table = table();
saturated_table = table();

if any(tbl.is_feasible)
    feasible_tbl = tbl(tbl.is_feasible, :);
    min_Ns = min(feasible_tbl.Ns);
    minimum_feasible_table = feasible_tbl(feasible_tbl.Ns == min_Ns, :);
else
    feasible_tbl = tbl([]);
    min_Ns = NaN;
end

if any(tbl.is_feasible)
    critical_boundary_table = tbl(tbl.is_feasible & tbl.joint_margin <= 1, :);
end

failed_table = tbl(~tbl.is_feasible, :);
saturated_table = tbl(tbl.joint_margin >= 2, :);

summary = struct();
summary.design_count = height(tbl);
summary.feasible_count = sum(tbl.is_feasible);
summary.failed_count = sum(~tbl.is_feasible);
summary.feasible_ratio = mean(double(tbl.is_feasible));

if isempty(minimum_feasible_table)
    summary.min_Ns = NaN;
    summary.min_design_count = 0;
else
    summary.min_Ns = min_Ns;
    summary.min_design_count = height(minimum_feasible_table);
end

summary.critical_count = height(critical_boundary_table);
summary.saturated_count = height(saturated_table);

summary_table = struct2table(summary);

boundary_result = struct();
boundary_result.minimum_feasible_table = minimum_feasible_table;
boundary_result.critical_boundary_table = critical_boundary_table;
boundary_result.failed_table = failed_table;
boundary_result.saturated_table = saturated_table;
boundary_result.summary_table = summary_table;
end
