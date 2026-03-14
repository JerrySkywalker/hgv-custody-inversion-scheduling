function report_file = stage11_export_report(out, cfg, timestamp)
%STAGE11_EXPORT_REPORT Export a compact markdown report for Stage11.

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    report_file = fullfile(cfg.paths.tables, ...
        sprintf('stage11_report_%s_%s.md', cfg.stage11.run_tag, timestamp));

    fid = fopen(report_file, 'w');
    if fid < 0
        error('Failed to open report file: %s', report_file);
    end
    cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    n_old_safe = sum(out.case_table.old_case_label == "safe_pass");
    n_new_safe = sum(out.case_table.new_case_label == "safe_pass");
    n_old_warn = sum(out.case_table.old_case_label == "warn_pass");
    n_new_warn = sum(out.case_table.new_case_label == "warn_pass");
    n_old_reject = sum(out.case_table.old_case_label == "reject");
    n_new_reject = sum(out.case_table.new_case_label == "reject");
    false_safe_new = sum((out.case_table.truth_case_pass == false) & (out.case_table.new_case_label == "safe_pass"));

    fprintf(fid, '# Stage11 Report\n\n');
    fprintf(fid, '- run_tag: `%s`\n', cfg.stage11.run_tag);
    fprintf(fid, '- source_stage10_entry: `%s`\n', cfg.stage11.source_stage10_entry);
    fprintf(fid, '- partition_mode: `%s`\n', cfg.stage11.partition_mode);
    fprintf(fid, '- n_theta: %d\n', out.summary_table.n_theta);
    fprintf(fid, '- n_case: %d\n', out.summary_table.n_case);
    fprintf(fid, '- n_window: %d\n\n', out.summary_table.n_window);

    fprintf(fid, '## Label Summary\n\n');
    fprintf(fid, '- old safe / warn / reject: %d / %d / %d\n', n_old_safe, n_old_warn, n_old_reject);
    fprintf(fid, '- new safe / warn / reject: %d / %d / %d\n', n_new_safe, n_new_warn, n_new_reject);
    fprintf(fid, '- false safe (new): %d\n\n', false_safe_new);

    fprintf(fid, '## Gap Summary\n\n');
    fprintf(fid, '- mean gap old: %.6g\n', mean(out.window_table.truth_lambda_min - out.window_table.old_bound));
    fprintf(fid, '- mean gap new: %.6g\n', mean(out.window_table.truth_lambda_min - out.window_table.L_new));
    fprintf(fid, '- mean L_weak: %.6g\n', mean(out.window_table.L_weak));
    fprintf(fid, '- mean L_sub: %.6g\n', mean(out.window_table.L_sub));
    fprintf(fid, '- mean L_partblk: %.6g\n', mean(out.window_table.L_partblk));
    fprintf(fid, '- mean L_new: %.6g\n', mean(out.window_table.L_new));
    fprintf(fid, '\n## Auxiliary Bound Note\n\n');
    fprintf(fid, '- `L_partblk` is treated as a partition-local auxiliary bound in this revision.\n');
    fprintf(fid, '- It is not reported as a strict block Gershgorin theorem validation result.\n');
end
