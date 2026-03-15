function case_table = stage11_aggregate_cases(case_table, window_table, cfg)
%STAGE11_AGGREGATE_CASES Aggregate Stage11 bounds with strict full-window semantics.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    n_case = height(case_table);
    L_weak_worst = nan(n_case, 1);
    L_sub_worst = nan(n_case, 1);
    L_partblk_worst = nan(n_case, 1);
    L_new_worst = nan(n_case, 1);
    Dg_new_worst = nan(n_case, 1);
    new_case_valid = false(n_case, 1);
    n_window_total = zeros(n_case, 1);
    n_window_valid_new = zeros(n_case, 1);
    valid_ratio_new = zeros(n_case, 1);
    all_valid_new = false(n_case, 1);
    n_failure_no_reference = zeros(n_case, 1);
    n_failure_partial_reference = zeros(n_case, 1);
    n_failure_reference_gap = zeros(n_case, 1);
    n_failure_weak_invalid = zeros(n_case, 1);
    n_failure_sub_invalid = zeros(n_case, 1);
    n_failure_all_bounds_invalid = zeros(n_case, 1);
    n_failure_numerical = zeros(n_case, 1);
    mean_reference_match_ratio = nan(n_case, 1);
    mean_supported_ratio = nan(n_case, 1);
    n_groups_fallback_total = zeros(n_case, 1);

    has_weak = ismember('L_weak', window_table.Properties.VariableNames);
    has_sub = ismember('L_sub', window_table.Properties.VariableNames);
    has_partblk = ismember('L_partblk', window_table.Properties.VariableNames);
    has_new = ismember('L_new', window_table.Properties.VariableNames);
    has_dg_new = ismember('Dg_new_window', window_table.Properties.VariableNames);
    has_new_valid = ismember('new_valid', window_table.Properties.VariableNames);

    for i = 1:n_case
        idx = case_table.window_index_list{i};
        n_total = numel(idx);
        n_window_total(i) = n_total;

        if has_weak
            L_weak_worst(i) = min(window_table.L_weak(idx));
        end
        if has_sub
            L_sub_worst(i) = min(window_table.L_sub(idx));
        end
        if has_partblk
            L_partblk_worst(i) = min(window_table.L_partblk(idx));
        end

        if has_new && has_new_valid
            n_valid = nnz(window_table.new_valid(idx));
            n_window_valid_new(i) = n_valid;
            valid_ratio_new(i) = n_valid / max(n_total, 1);
            all_valid_new(i) = (n_valid == n_total);
            new_case_valid(i) = n_valid > 0;

            % Only all-valid cases are allowed to inherit a strict worst-window new bound.
            if all_valid_new(i)
                L_new_worst(i) = min(window_table.L_new(idx));
                if has_dg_new
                    Dg_new_worst(i) = min(window_table.Dg_new_window(idx));
                end
            end
        end

        if ismember('new_failure_reason', window_table.Properties.VariableNames)
            reasons = string(window_table.new_failure_reason(idx));
            n_failure_no_reference(i) = sum(reasons == "no_reference_match");
            n_failure_partial_reference(i) = sum(reasons == "partial_reference_match");
            n_failure_reference_gap(i) = sum(reasons == "reference_gap");
            n_failure_weak_invalid(i) = sum(reasons == "weak_invalid");
            n_failure_sub_invalid(i) = sum(reasons == "sub_invalid");
            n_failure_all_bounds_invalid(i) = sum(reasons == "all_bounds_invalid");
            n_failure_numerical(i) = sum(reasons == "numerical_issue");
        end
        if ismember('reference_match_ratio', window_table.Properties.VariableNames)
            mean_reference_match_ratio(i) = mean(window_table.reference_match_ratio(idx), 'omitnan');
        end
        if ismember('supported_ratio', window_table.Properties.VariableNames)
            mean_supported_ratio(i) = mean(window_table.supported_ratio(idx), 'omitnan');
        end
        if ismember('n_groups_fallback', window_table.Properties.VariableNames)
            n_groups_fallback_total(i) = sum(window_table.n_groups_fallback(idx), 'omitnan');
        end
    end

    case_table.L_weak_worst = L_weak_worst;
    case_table.L_sub_worst = L_sub_worst;
    case_table.L_partblk_worst = L_partblk_worst;
    case_table.L_new_worst = L_new_worst;
    case_table.Dg_new_worst = Dg_new_worst;
    case_table.new_case_valid = new_case_valid;
    case_table.n_window_total = n_window_total;
    case_table.n_window_valid_new = n_window_valid_new;
    case_table.valid_ratio_new = valid_ratio_new;
    case_table.all_valid_new = all_valid_new;
    case_table.n_failure_no_reference = n_failure_no_reference;
    case_table.n_failure_partial_reference = n_failure_partial_reference;
    case_table.n_failure_reference_gap = n_failure_reference_gap;
    case_table.n_failure_weak_invalid = n_failure_weak_invalid;
    case_table.n_failure_sub_invalid = n_failure_sub_invalid;
    case_table.n_failure_all_bounds_invalid = n_failure_all_bounds_invalid;
    case_table.n_failure_numerical = n_failure_numerical;
    case_table.mean_reference_match_ratio = mean_reference_match_ratio;
    case_table.mean_supported_ratio = mean_supported_ratio;
    case_table.n_groups_fallback_total = n_groups_fallback_total;
    case_table.new_case_label = strings(n_case, 1);

    for i = 1:n_case
        if case_table.n_window_valid_new(i) == 0
            case_table.new_case_label(i) = "reject";
        elseif ~case_table.all_valid_new(i)
            case_table.new_case_label(i) = "warn_pass";
        elseif case_table.Dg_new_worst(i) >= 1
            case_table.new_case_label(i) = "safe_pass";
        else
            case_table.new_case_label(i) = "warn_pass";
        end
    end
end
