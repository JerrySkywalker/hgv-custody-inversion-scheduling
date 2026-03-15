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
    fprintf(fid, '- cache_reuse_mode: `%s`\n', out.summary_table.cache_reuse_mode);
    fprintf(fid, '- n_windows_reused: %d\n', out.summary_table.n_windows_reused);
    fprintf(fid, '- n_windows_recomputed: %d\n\n', out.summary_table.n_windows_recomputed);

    fprintf(fid, '## Label Summary\n\n');
    fprintf(fid, '- old safe / warn / reject: %d / %d / %d\n', n_old_safe, n_old_warn, n_old_reject);
    fprintf(fid, '- new safe / warn / reject: %d / %d / %d\n', n_new_safe, n_new_warn, n_new_reject);
    fprintf(fid, '- false safe (new): %d\n\n', false_safe_new);

    if ismember('valid_ratio_new', out.case_table.Properties.VariableNames)
        fprintf(fid, '## Coverage Summary\n\n');
        fprintf(fid, '- mean valid ratio (new): %.6g\n', local_mean_finite(out.case_table.valid_ratio_new));
        fprintf(fid, '- median valid ratio (new): %.6g\n', median(out.case_table.valid_ratio_new, 'omitnan'));
        fprintf(fid, '- min valid ratio (new): %.6g\n', min(out.case_table.valid_ratio_new, [], 'omitnan'));
        fprintf(fid, '- all-valid cases: %d\n', sum(out.case_table.all_valid_new));
        fprintf(fid, '- partial-valid cases: %d\n', sum(out.case_table.n_window_valid_new > 0 & ~out.case_table.all_valid_new));
        fprintf(fid, '- zero-valid cases: %d\n\n', sum(out.case_table.n_window_valid_new == 0));
    end

    fprintf(fid, '## Gap Summary\n\n');
    fprintf(fid, '- mean gap old: %.6g\n', local_mean_finite(out.window_table.truth_lambda_min - out.window_table.old_bound));
    fprintf(fid, '- mean gap new: %.6g\n', local_mean_finite(out.window_table.truth_lambda_min - out.window_table.L_new));
    fprintf(fid, '- mean L_weak: %.6g\n', local_mean_finite(out.window_table.L_weak));
    fprintf(fid, '- mean L_sub: %.6g\n', local_mean_finite(out.window_table.L_sub));
    if ismember('L_partblk', out.window_table.Properties.VariableNames) && any(isfinite(out.window_table.L_partblk))
        fprintf(fid, '- mean L_partblk: %.6g\n', local_mean_finite(out.window_table.L_partblk));
    end
    fprintf(fid, '- mean L_new: %.6g\n', local_mean_finite(out.window_table.L_new));
    if ismember('L_partblk', out.window_table.Properties.VariableNames) && any(isfinite(out.window_table.L_partblk))
        fprintf(fid, '\n## Auxiliary Bound Note\n\n');
        fprintf(fid, '- `L_partblk` is treated as a partition-local auxiliary bound in this revision.\n');
        fprintf(fid, '- It is not reported as a strict block Gershgorin theorem validation result.\n');
    end

    if isfield(out, 'sanity_table') && ~isempty(out.sanity_table)
        S = out.sanity_table(1,:);
        fprintf(fid, '\n## Sanity Checks\n\n');
        fprintf(fid, '- eta_pi min / median / max: %.6g / %.6g / %.6g\n', S.eta_pi_min, S.eta_pi_median, S.eta_pi_max);
        fprintf(fid, '- delta_sub min / median / max: %.6g / %.6g / %.6g\n', S.delta_sub_min, S.delta_sub_median, S.delta_sub_max);
        fprintf(fid, '- delta_new min / median / max: %.6g / %.6g / %.6g\n', S.delta_new_min, S.delta_new_median, S.delta_new_max);
        fprintf(fid, '- reference_leak_ratio: %.6g\n', S.reference_leak_ratio);
        fprintf(fid, '- sub_overlap_ratio: %.6g\n', S.sub_overlap_ratio);
        fprintf(fid, '- joint_gap_ratio: %.6g\n', S.joint_gap_ratio);
        fprintf(fid, '- best_source_sub_ratio: %.6g\n', S.best_source_sub_ratio);
        fprintf(fid, '- sanity_fail_reference_leakage: %d\n', S.sanity_fail_reference_leakage);
        fprintf(fid, '- sanity_fail_sub_truth_overlap: %d\n', S.sanity_fail_sub_truth_overlap);
        fprintf(fid, '- sanity_fail_joint_gap_collapse: %d\n', S.sanity_fail_joint_gap_collapse);
        fprintf(fid, '- sanity_fail_best_source_sub_dominance: %d\n', S.sanity_fail_best_source_sub_dominance);
    end
end


function value = local_mean_finite(x)
    x = x(isfinite(x));
    if isempty(x)
        value = NaN;
    else
        value = mean(x);
    end
end
