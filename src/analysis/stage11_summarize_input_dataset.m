function summary_table = stage11_summarize_input_dataset(input_source, cfg)
%STAGE11_SUMMARIZE_INPUT_DATASET Build a compact summary for Stage11.A/B.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    if isfield(input_source, 'input_dataset')
        input_dataset = input_source.input_dataset;
    else
        input_dataset = input_source;
    end
    if isfield(input_source, 'case_table') && ~isempty(input_source.case_table)
        case_table = input_source.case_table;
    else
        case_table = input_dataset.case_table;
    end

    n_window = height(input_dataset.window_table);
    n_case = height(case_table);
    n_theta = numel(unique(case_table.theta_id));

    summary_table = table( ...
        string(cfg.stage11.source_stage10_entry), ...
        string(cfg.stage11.partition_mode), ...
        n_theta, n_case, n_window, ...
        string(input_dataset.cache_reuse_mode), ...
        input_dataset.n_windows_reused, ...
        input_dataset.n_windows_recomputed, ...
        'VariableNames', {'source_stage10_entry', 'partition_mode', 'n_theta', 'n_case', 'n_window', ...
        'cache_reuse_mode', 'n_windows_reused', 'n_windows_recomputed'});

    if isfield(input_source, 'weak_table') && ~isempty(input_source.weak_table)
        weak_table = input_source.weak_table;
        summary_table.n_weak_valid = sum(weak_table.weak_valid);
        summary_table.mean_eps_pi = local_mean_finite(weak_table.eps_pi);
        summary_table.mean_L_weak = local_mean_finite(weak_table.L_weak);
    end
    if isfield(input_source, 'sub_table') && ~isempty(input_source.sub_table)
        summary_table.n_sub_valid = sum(input_source.sub_table.sub_valid);
        summary_table.mean_L_sub = local_mean_finite(input_source.sub_table.L_sub);
    end
    if isfield(input_source, 'blk_table') && ~isempty(input_source.blk_table)
        summary_table.n_partblk_valid = sum(input_source.blk_table.partblk_valid);
        summary_table.mean_L_partblk = local_mean_finite(input_source.blk_table.L_partblk);
    end
    if isfield(input_source, 'joint_table') && ~isempty(input_source.joint_table)
        summary_table.n_new_valid = sum(input_source.joint_table.new_valid);
        summary_table.mean_L_new = local_mean_finite(input_source.joint_table.L_new);
    end
    if ismember('valid_ratio_new', case_table.Properties.VariableNames)
        valid_ratio = case_table.valid_ratio_new;
        summary_table.mean_valid_ratio_new = local_mean_finite(valid_ratio);
        summary_table.median_valid_ratio_new = median(valid_ratio, 'omitnan');
        summary_table.min_valid_ratio_new = min(valid_ratio, [], 'omitnan');
        summary_table.n_case_all_valid_new = sum(case_table.all_valid_new);
        summary_table.n_case_partial_valid_new = sum(case_table.n_window_valid_new > 0 & ~case_table.all_valid_new);
        summary_table.n_case_zero_valid_new = sum(case_table.n_window_valid_new == 0);
    end
    if isfield(input_source, 'diagnosis_summary_table') && ~isempty(input_source.diagnosis_summary_table)
        D = input_source.diagnosis_summary_table(1,:);
        summary_table.diagnosis_valid_ratio = D.valid_ratio;
        summary_table.diagnosis_partial_valid_cases = D.partial_valid_cases;
        summary_table.diagnosis_zero_valid_cases = D.zero_valid_cases;
    end
    if isfield(input_source, 'diagnosis_failure_table') && ~isempty(input_source.diagnosis_failure_table)
        F = input_source.diagnosis_failure_table;
        F = F(F.failure_reason ~= "ok", :);
        [~, idx_max] = max(F.count);
        if ~isempty(idx_max) && F.count(idx_max) > 0
            summary_table.dominant_failure_reason = F.failure_reason(idx_max);
            summary_table.dominant_failure_count = F.count(idx_max);
            summary_table.dominant_failure_ratio = F.ratio(idx_max);
        else
            summary_table.dominant_failure_reason = "none";
            summary_table.dominant_failure_count = 0;
            summary_table.dominant_failure_ratio = 0;
        end
    end
    if isfield(input_source, 'sanity_table') && ~isempty(input_source.sanity_table)
        summary_table.sanity_fail_reference_leakage = input_source.sanity_table.sanity_fail_reference_leakage(1);
        summary_table.sanity_fail_sub_truth_overlap = input_source.sanity_table.sanity_fail_sub_truth_overlap(1);
        summary_table.sanity_fail_joint_gap_collapse = input_source.sanity_table.sanity_fail_joint_gap_collapse(1);
        summary_table.sanity_fail_best_source_sub_dominance = input_source.sanity_table.sanity_fail_best_source_sub_dominance(1);
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
