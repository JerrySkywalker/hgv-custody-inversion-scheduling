function export_out = stage13_export_for_dissertation(stage13_out)
%STAGE13_EXPORT_FOR_DISSERTATION Export lightweight cherry-pick recommendations.

reps = stage13_out.summary.representatives;

export_out = struct();
export_out.recommended_dt_case = local_pick_case(reps.dt_first_probe);
export_out.recommended_dg_case = local_pick_case(reps.dg_first_probe);
export_out.recommended_dg_case_refined = "";
export_out.notes_for_MA_extension = [ ...
    "优先考虑将 " + export_out.recommended_dt_case + ...
    " 作为 MA 基线邻域对照案例，用于说明基线附近时序/结构约束切换时的窗口曲线变化。"];
export_out.notes_for_MB_integration = [ ...
    "优先考虑将 " + export_out.recommended_dg_case + ...
    " 作为 MB 任务几何主导反例，用于补充真值静态可行域之外的几何退化解释。"];

if isfield(stage13_out, 'dg_refine') && isstruct(stage13_out.dg_refine) && ...
        isfield(stage13_out.dg_refine, 'recommended_case') && strlength(string(stage13_out.dg_refine.recommended_case)) > 0
    export_out.recommended_dg_case_refined = string(stage13_out.dg_refine.recommended_case);
    export_out.dg_refined_review = local_build_refined_review(stage13_out);
else
    export_out.dg_refined_review = "DG refined search 未开启，本轮导出仍以原始 dg_first_probe 推荐为准。";
end

fid = fopen(stage13_out.paths.export_md, 'w');
if fid < 0
    error('Failed to open Stage13 dissertation export report: %s', stage13_out.paths.export_md);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# Stage13 dissertation export\n\n');
fprintf(fid, '- recommended dt case: `%s`\n', export_out.recommended_dt_case);
fprintf(fid, '- recommended dg case: `%s`\n', export_out.recommended_dg_case);
fprintf(fid, '- recommended dg case refined: `%s`\n', export_out.recommended_dg_case_refined);
fprintf(fid, '- notes for MA extension: %s\n', export_out.notes_for_MA_extension);
fprintf(fid, '- notes for MB integration: %s\n', export_out.notes_for_MB_integration);
fprintf(fid, '- dg refined review: %s\n', export_out.dg_refined_review);

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

function review_text = local_build_refined_review(stage13_out)
old_case = string(local_pick_case(stage13_out.summary.representatives.dg_first_probe));
new_case = string(stage13_out.dg_refine.recommended_case);
rows = stage13_out.dg_refine.summary;
row = rows(strcmp(string(rows.case_tag), new_case), :);

if isempty(row)
    review_text = "DG refined candidate summary 缺失，建议仅保留原始 dg_first_probe 输出。";
    return;
end

is_clean_enough = logical(row.is_dg_min(1)) && row.D_G_worst(1) < row.D_A_worst(1) && ...
    row.D_T_worst(1) > 1.0 && row.D_A_worst(1) >= 0.6;

if is_clean_enough
    review_text = sprintf([ ...
        '%s 相比 %s 已显著减轻整体塌陷：当前 D_G^{worst}=%.3f, D_A^{worst}=%.3f, D_T^{worst}=%.3f，' ...
        '更接近 DG 优先退化机理，建议优先作为正文候选。'], ...
        new_case, old_case, row.D_G_worst(1), row.D_A_worst(1), row.D_T_worst(1));
else
    review_text = sprintf([ ...
        '%s 相比 %s 已从 joint collapse 改善为 DG 主导退化，当前 D_G^{worst}=%.3f, D_A^{worst}=%.3f, D_T^{worst}=%.3f；' ...
        '其中 DT 保持在门槛，但 DA 仍同步明显下降，因此更适合作为备选/答辩材料，不建议立即正文 cherry-pick。'], ...
        new_case, old_case, row.D_G_worst(1), row.D_A_worst(1), row.D_T_worst(1));
end
end
