function [sanity_table, sanity_flags] = stage11_sanity_checks(out, cfg)
%STAGE11_SANITY_CHECKS Run Stage11 certificate-independence and aggregation sanity checks.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    tol = 1e-10;
    dominance_threshold = 0.95;

    eta_pi = local_get_column(out.window_table, 'eta_pi');
    delta_sub = local_get_column(out.window_table, 'truth_lambda_min') - local_get_column(out.window_table, 'L_sub');
    delta_new = local_get_column(out.window_table, 'truth_lambda_min') - local_get_column(out.window_table, 'L_new');
    best_source = strings(height(out.window_table), 1);
    if ismember('best_bound_source', out.window_table.Properties.VariableNames)
        best_source = string(out.window_table.best_bound_source);
    end

    reference_leak_ratio = mean(eta_pi < tol, 'omitnan');
    sub_overlap_ratio = mean(abs(delta_sub) < tol, 'omitnan');
    joint_gap_ratio = mean(abs(delta_new) < tol, 'omitnan');
    part_sub_ratio = mean(best_source == "sub", 'omitnan');

    [safe_without_all_valid, safe_without_threshold, rep_case_conflict] = local_case_consistency_checks(out);

    sanity_flags = struct();
    sanity_flags.reference_leakage = reference_leak_ratio > 0.5;
    sanity_flags.sub_truth_overlap = sub_overlap_ratio > 0.5;
    sanity_flags.joint_gap_collapse = joint_gap_ratio > 0.5;
    sanity_flags.best_source_sub_dominance = ...
        (part_sub_ratio > dominance_threshold) && (sanity_flags.sub_truth_overlap || sanity_flags.joint_gap_collapse);
    sanity_flags.safe_case_without_all_valid = safe_without_all_valid > 0;
    sanity_flags.safe_case_threshold_violation = safe_without_threshold > 0;
    sanity_flags.representative_case_conflict = rep_case_conflict > 0;

    sanity_table = table( ...
        min(eta_pi, [], 'omitnan'), median(eta_pi, 'omitnan'), max(eta_pi, [], 'omitnan'), reference_leak_ratio, ...
        min(delta_sub, [], 'omitnan'), median(delta_sub, 'omitnan'), max(delta_sub, [], 'omitnan'), sub_overlap_ratio, ...
        min(delta_new, [], 'omitnan'), median(delta_new, 'omitnan'), max(delta_new, [], 'omitnan'), joint_gap_ratio, ...
        part_sub_ratio, ...
        safe_without_all_valid, safe_without_threshold, rep_case_conflict, ...
        logical(sanity_flags.reference_leakage), ...
        logical(sanity_flags.sub_truth_overlap), ...
        logical(sanity_flags.joint_gap_collapse), ...
        logical(sanity_flags.best_source_sub_dominance), ...
        logical(sanity_flags.safe_case_without_all_valid), ...
        logical(sanity_flags.safe_case_threshold_violation), ...
        logical(sanity_flags.representative_case_conflict), ...
        'VariableNames', { ...
            'eta_pi_min', 'eta_pi_median', 'eta_pi_max', 'reference_leak_ratio', ...
            'delta_sub_min', 'delta_sub_median', 'delta_sub_max', 'sub_overlap_ratio', ...
            'delta_new_min', 'delta_new_median', 'delta_new_max', 'joint_gap_ratio', ...
            'best_source_sub_ratio', ...
            'safe_case_without_all_valid_count', ...
            'safe_case_threshold_violation_count', ...
            'representative_case_conflict_count', ...
            'sanity_fail_reference_leakage', ...
            'sanity_fail_sub_truth_overlap', ...
            'sanity_fail_joint_gap_collapse', ...
            'sanity_fail_best_source_sub_dominance', ...
            'sanity_fail_safe_case_without_all_valid', ...
            'sanity_fail_safe_case_threshold_violation', ...
            'sanity_fail_representative_case_conflict'});
end


function [safe_without_all_valid, safe_without_threshold, rep_case_conflict] = local_case_consistency_checks(out)
    safe_without_all_valid = 0;
    safe_without_threshold = 0;
    rep_case_conflict = 0;

    if isempty(out.case_table) || ~ismember('new_case_label', out.case_table.Properties.VariableNames)
        return;
    end

    case_table = out.case_table;
    window_table = out.window_table;
    safe_mask = (case_table.new_case_label == "safe_pass");

    if any(safe_mask) && ismember('all_valid_new', case_table.Properties.VariableNames)
        safe_without_all_valid = sum(~case_table.all_valid_new(safe_mask));
    end

    if any(safe_mask) && ismember('Dg_new_window', window_table.Properties.VariableNames)
        safe_rows = find(safe_mask);
        for i = 1:numel(safe_rows)
            idx = case_table.window_index_list{safe_rows(i)};
            if any(~isfinite(window_table.Dg_new_window(idx))) || min(window_table.Dg_new_window(idx)) < 1
                safe_without_threshold = safe_without_threshold + 1;
            end
        end
    end

    rep_case_index = case_table.case_index(1);
    if ismember('all_valid_new', case_table.Properties.VariableNames) && ismember('new_case_label', case_table.Properties.VariableNames)
        rep_case = case_table(case_table.case_index == rep_case_index, :);
        if ~isempty(rep_case)
            idx = rep_case.window_index_list{1};
            if rep_case.new_case_label(1) == "safe_pass"
                if any(~window_table.new_valid(idx)) || any(window_table.Dg_new_window(idx) < 1, 'omitnan')
                    rep_case_conflict = 1;
                end
            end
        end
    end
end


function values = local_get_column(T, name)
    if ismember(name, T.Properties.VariableNames)
        values = T.(name);
    else
        values = nan(height(T), 1);
    end
end
