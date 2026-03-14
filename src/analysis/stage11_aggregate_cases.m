function case_table = stage11_aggregate_cases(case_table, window_table)
%STAGE11_AGGREGATE_CASES Aggregate window-level Stage11 bounds to case-level rows.

    n_case = height(case_table);
    L_weak_worst = nan(n_case, 1);
    L_sub_worst = nan(n_case, 1);
    L_blk_worst = nan(n_case, 1);
    L_new_worst = nan(n_case, 1);
    new_case_valid = false(n_case, 1);

    has_weak = ismember('L_weak', window_table.Properties.VariableNames);
    has_sub = ismember('L_sub', window_table.Properties.VariableNames);
    has_blk = ismember('L_blk', window_table.Properties.VariableNames);
    has_new = ismember('L_new', window_table.Properties.VariableNames);

    for i = 1:n_case
        idx = case_table.window_index_list{i};
        if has_weak
            L_weak_worst(i) = min(window_table.L_weak(idx));
        end
        if has_sub
            L_sub_worst(i) = min(window_table.L_sub(idx));
        end
        if has_blk
            L_blk_worst(i) = min(window_table.L_blk(idx));
        end
        if has_new
            L_new_worst(i) = min(window_table.L_new(idx));
            new_case_valid(i) = all(window_table.new_valid(idx));
        end
    end

    case_table.L_weak_worst = L_weak_worst;
    case_table.L_sub_worst = L_sub_worst;
    case_table.L_blk_worst = L_blk_worst;
    case_table.L_new_worst = L_new_worst;
    case_table.new_case_valid = new_case_valid;
end
