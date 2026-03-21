function report = build_mb_gap_reliability_report(comparison_summary, comparison_grade)
%BUILD_MB_GAP_RELIABILITY_REPORT Summarize comparison-gap reliability from exported summaries.

if nargin < 1 || isempty(comparison_summary)
    comparison_summary = table();
end
if nargin < 2 || isempty(comparison_grade)
    comparison_grade = table();
end
if isempty(comparison_summary)
    report = table();
    return;
end

row_count = height(comparison_summary);
report = table('Size', [row_count, 13], ...
    'VariableTypes', {'double', 'string', 'double', 'double', 'double', 'logical', 'logical', 'double', 'logical', 'logical', 'logical', 'string', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'semantic_gap_max', 'semantic_gap_at_end', 'gap_sign_changes_count', ...
    'right_plateau_reached_legacy', 'right_plateau_reached_closed', 'frontier_delta_defined_count', ...
    'boundary_dominated_result', 'legacy_unsaturated', 'closed_unsaturated', 'reliability_grade', 'note'});

report.h_km = double(comparison_summary.h_km);
report.family_name = string(comparison_summary.family_name);
report.semantic_gap_max = double(comparison_summary.semantic_gap_max);
report.semantic_gap_at_end = double(comparison_summary.semantic_gap_at_end);
report.gap_sign_changes_count = double(comparison_summary.gap_sign_changes_count);
report.right_plateau_reached_legacy = logical(comparison_summary.right_plateau_reached_legacy);
report.right_plateau_reached_closed = logical(comparison_summary.right_plateau_reached_closed);
report.frontier_delta_defined_count = double(comparison_summary.frontier_delta_defined_count);
report.boundary_dominated_result = logical(comparison_summary.boundary_dominated_result);
report.legacy_unsaturated = logical(comparison_summary.legacy_is_search_domain_unsaturated);
report.closed_unsaturated = logical(comparison_summary.closed_is_search_domain_unsaturated);
report.reliability_grade = strings(row_count, 1);
report.note = strings(row_count, 1);

for idx = 1:row_count
    [report.reliability_grade(idx), report.note(idx)] = local_grade_row(comparison_summary(idx, :), comparison_grade);
end
end

function [grade, note] = local_grade_row(summary_row, comparison_grade)
grade = "good";
reasons = strings(0, 1);
if logical(summary_row.boundary_dominated_result)
    grade = "diagnostic_only";
    reasons(end + 1, 1) = "boundary dominated"; %#ok<AGROW>
end
if ~logical(summary_row.right_plateau_reached_legacy) || ~logical(summary_row.right_plateau_reached_closed)
    grade = "diagnostic_only";
    reasons(end + 1, 1) = "unity plateau not reached"; %#ok<AGROW>
end
if double(summary_row.frontier_delta_defined_count) <= 1
    if grade == "good"
        grade = "weak";
    end
    reasons(end + 1, 1) = "frontier shift weakly defined"; %#ok<AGROW>
end

if ~isempty(comparison_grade) && istable(comparison_grade)
    hit = comparison_grade.h_km == summary_row.h_km & comparison_grade.paper_ready_allowed == false;
    if any(hit)
        grade = "diagnostic_only";
        notes = unique(string(comparison_grade.note(hit)));
        notes = notes(strlength(notes) > 0);
        reasons = [reasons; notes]; %#ok<AGROW>
    end
end

reasons = unique(reasons(strlength(reasons) > 0), 'stable');
if isempty(reasons)
    note = "comparison gap is sufficiently supported by the current expanded-final domain";
else
    note = strjoin(cellstr(reasons), '; ');
end
end
