function joint_table = stage11_compute_joint_bound(window_table, weak_table, sub_table, blk_table, cfg)
%STAGE11_COMPUTE_JOINT_BOUND Combine weak/sub/block bounds into L_new.

    if nargin < 5 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    n_window = height(window_table);
    rows = cell(n_window, 1);

    for i = 1:n_window
        values = [-inf, -inf, -inf];
        names = ["weak", "sub", "blk"];
        if cfg.stage11.enable_weak
            values(1) = weak_table.L_weak(i);
        end
        if cfg.stage11.enable_sub
            values(2) = sub_table.L_sub(i);
        end
        if cfg.stage11.enable_blk
            values(3) = blk_table.L_blk(i);
        end

        [L_new, idx_best] = max(values);
        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', window_table.row_id(i), ...
            'L_new', L_new, ...
            'best_bound_source', string(names(idx_best)), ...
            'new_valid', window_table.truth_lambda_min(i) + 1e-9 >= L_new);
    end

    joint_table = struct2table(vertcat(rows{:}));
end
