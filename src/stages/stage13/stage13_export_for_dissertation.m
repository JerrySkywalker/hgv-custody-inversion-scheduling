function export_out = stage13_export_for_dissertation(stage13_out)
%STAGE13_EXPORT_FOR_DISSERTATION Export lightweight cherry-pick recommendations.

reps = stage13_out.summary.representatives;

export_out = struct();
export_out.recommended_dt_case = local_pick_case(reps.dt_first_probe);
export_out.recommended_dg_case = local_pick_case(reps.dg_first_probe);
export_out.notes_for_MA_extension = [ ...
    "优先考虑将 " + export_out.recommended_dt_case + ...
    " 作为 MA 基线邻域对照案例，用于说明基线附近时序/结构约束切换时的窗口曲线变化。"];
export_out.notes_for_MB_integration = [ ...
    "优先考虑将 " + export_out.recommended_dg_case + ...
    " 作为 MB 任务几何主导反例，用于补充真值静态可行域之外的几何退化解释。"];

fid = fopen(stage13_out.paths.export_md, 'w');
if fid < 0
    error('Failed to open Stage13 dissertation export report: %s', stage13_out.paths.export_md);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# Stage13 dissertation export\n\n');
fprintf(fid, '- recommended dt case: `%s`\n', export_out.recommended_dt_case);
fprintf(fid, '- recommended dg case: `%s`\n', export_out.recommended_dg_case);
fprintf(fid, '- notes for MA extension: %s\n', export_out.notes_for_MA_extension);
fprintf(fid, '- notes for MB integration: %s\n', export_out.notes_for_MB_integration);

save(stage13_out.paths.export_mat, 'export_out', '-v7.3');
end

function case_tag = local_pick_case(rep_struct)
case_tag = string(rep_struct.first_failure_case);
if strlength(case_tag) == 0
    case_tag = string(rep_struct.strongest_active_case);
end
if strlength(case_tag) == 0
    case_tag = string(rep_struct.closest_feasible_case);
end
end
