function summary_table = stage13_write_summary_table(signature_table, baseline_tags, out_csv)
%STAGE13_WRITE_SUMMARY_TABLE Build Stage13 candidate summary table and save it.

summary_table = table('Size', [0 11], ...
    'VariableTypes', {'string', 'string', 'logical', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'case_tag', 'family', 'feasible_truth', 'active_constraint', ...
    'D_G_worst', 'D_A_worst', 'D_T_worst', 'delta_vs_baseline_DG', 'delta_vs_baseline_DA', 'delta_vs_baseline_DT', 't0_star_summary'});

families = unique(string(signature_table.family), 'stable');
for i = 1:numel(families)
    family_name = families(i);
    family_rows = signature_table(strcmp(string(signature_table.family), family_name), :);
    if isempty(family_rows)
        continue;
    end
    baseline_tag = string(baseline_tags.(char(family_name)));
    baseline_row = family_rows(strcmp(string(family_rows.case_tag), baseline_tag), :);
    if isempty(baseline_row)
        baseline_row = family_rows(1, :);
    end

    for k = 1:height(family_rows)
        row = family_rows(k, :);
        summary_table = [summary_table; { ...
            string(row.case_tag), string(row.family), row.feasible_truth, string(row.active_constraint), ...
            row.D_G_worst, row.D_A_worst, row.D_T_worst, ...
            row.D_G_worst - baseline_row.D_G_worst, ...
            row.D_A_worst - baseline_row.D_A_worst, ...
            row.D_T_worst - baseline_row.D_T_worst, ...
            sprintf('(%g, %g, %g)', row.t0G_star, row.t0A_star, row.t0T_star)}]; %#ok<AGROW>
    end
end

if nargin >= 3 && ~isempty(out_csv)
    writetable(summary_table, out_csv);
end
end
