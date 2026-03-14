function case_table = stage11_aggregate_cases(case_table, window_table, cfg)
%STAGE11_AGGREGATE_CASES Aggregate window-level Stage11 bounds to case-level rows.

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

    has_weak = ismember('L_weak', window_table.Properties.VariableNames);
    has_sub = ismember('L_sub', window_table.Properties.VariableNames);
    has_partblk = ismember('L_partblk', window_table.Properties.VariableNames);
    has_new = ismember('L_new', window_table.Properties.VariableNames);
    has_dg_new = ismember('Dg_new_window', window_table.Properties.VariableNames);

    for i = 1:n_case
        idx = case_table.window_index_list{i};
        if has_weak
            L_weak_worst(i) = min(window_table.L_weak(idx));
        end
        if has_sub
            L_sub_worst(i) = min(window_table.L_sub(idx));
        end
        if has_partblk
            L_partblk_worst(i) = min(window_table.L_partblk(idx));
        end
        if has_new
            valid_idx = idx(window_table.new_valid(idx));
            if ~isempty(valid_idx)
                L_new_worst(i) = min(window_table.L_new(valid_idx));
                if has_dg_new
                    Dg_new_worst(i) = min(window_table.Dg_new_window(valid_idx));
                end
                new_case_valid(i) = true;
            end
        end
    end

    case_table.L_weak_worst = L_weak_worst;
    case_table.L_sub_worst = L_sub_worst;
    case_table.L_partblk_worst = L_partblk_worst;
    case_table.L_new_worst = L_new_worst;
    case_table.Dg_new_worst = Dg_new_worst;
    case_table.new_case_valid = new_case_valid;
    case_table.new_case_label = strings(n_case, 1);
    for i = 1:n_case
        if ~case_table.new_case_valid(i)
            case_table.new_case_label(i) = "reject";
        elseif case_table.Dg_new_worst(i) >= 1
            case_table.new_case_label(i) = "safe_pass";
        else
            case_table.new_case_label(i) = "warn_pass";
        end
    end
end
