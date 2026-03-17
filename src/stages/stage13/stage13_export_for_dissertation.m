function export_out = stage13_export_for_dissertation(stage13_out)
%STAGE13_EXPORT_FOR_DISSERTATION Export fixed tier mapping for dissertation use.

export_out = struct();
export_out.recommended_for_MA = "dt_first_probe_P6T4F0";
export_out.backup_for_MB_or_defense = "dg_micro_07";
export_out.development_only = "dg_first_probe_3";
export_out.recommended_dt_case = export_out.recommended_for_MA;
export_out.recommended_dg_case = export_out.development_only;
export_out.recommended_dg_case_refined = export_out.backup_for_MB_or_defense;
export_out.notes_for_MA_extension = [ ...
    "Use " + export_out.recommended_for_MA + ...
    " as the only formal MA extension case to support the baseline-neighborhood DT-sensitivity conclusion."];
export_out.notes_for_MB_integration = [ ...
    export_out.backup_for_MB_or_defense + ...
    " remains a backup-only DG refined case for MB or defense discussion and is not promoted into MA正文导出."];
export_out.notes_for_development_only = [ ...
    export_out.development_only + ...
    " remains a development trace only and should not be auto-promoted into dissertation exports."];

if isfield(stage13_out, 'dg_refine') && isstruct(stage13_out.dg_refine) && ...
        isfield(stage13_out.dg_refine, 'recommended_case') && strlength(string(stage13_out.dg_refine.recommended_case)) > 0
    export_out.dg_refined_review = local_build_refined_review(stage13_out);
else
    export_out.dg_refined_review = "DG refined search is not required for MA export; the fixed tier mapping above remains in force.";
end

fid = fopen(stage13_out.paths.export_md, 'w');
if fid < 0
    error('Failed to open Stage13 dissertation export report: %s', stage13_out.paths.export_md);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Stage13 dissertation export\n\n');
fprintf(fid, '## Tiered candidate mapping\n\n');
fprintf(fid, '- recommended_for_MA: `%s`\n', export_out.recommended_for_MA);
fprintf(fid, '- backup_for_MB_or_defense: `%s`\n', export_out.backup_for_MB_or_defense);
fprintf(fid, '- development_only: `%s`\n', export_out.development_only);
fprintf(fid, '\n## Export notes\n\n');
fprintf(fid, '- MA extension note: %s\n', export_out.notes_for_MA_extension);
fprintf(fid, '- MB/defense backup note: %s\n', export_out.notes_for_MB_integration);
fprintf(fid, '- development-only note: %s\n', export_out.notes_for_development_only);
fprintf(fid, '- dg refined review: %s\n', export_out.dg_refined_review);

save(stage13_out.paths.export_mat, 'export_out', '-v7.3');
end

function review_text = local_build_refined_review(stage13_out)
new_case = "dg_micro_07";
row = local_find_refined_row(stage13_out, new_case);
if isempty(row)
    review_text = "DG refined candidate summary is unavailable; keep dg_micro_07 as a backup-only reference without promoting it.";
    return;
end

review_text = sprintf([ ...
    '%s shows a more active DG constraint than the original dg_first_probe_3 baseline probe ', ...
    '(D_G^{worst}=%.3f, D_A^{worst}=%.3f, D_T^{worst}=%.3f), ', ...
    'but it is still reserved for backup or defense use instead of MA正文导出.'], ...
    new_case, row.D_G_worst(1), row.D_A_worst(1), row.D_T_worst(1));
end

function row = local_find_refined_row(stage13_out, case_tag)
row = table();

if isfield(stage13_out, 'dg_refine') && isfield(stage13_out.dg_refine, 'summary')
    rows = stage13_out.dg_refine.summary;
    row = rows(strcmp(string(rows.case_tag), string(case_tag)), :);
    if ~isempty(row)
        return;
    end
end

if isfield(stage13_out, 'dg_refine') && isfield(stage13_out.dg_refine, 'micro') && ...
        isfield(stage13_out.dg_refine.micro, 'summary')
    rows = stage13_out.dg_refine.micro.summary;
    row = rows(strcmp(string(rows.case_tag), string(case_tag)), :);
end
end
