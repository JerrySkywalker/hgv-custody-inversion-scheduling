function joint_table = stage11_compute_joint_bound(window_table, weak_table, sub_table, blk_table, cfg)
%STAGE11_COMPUTE_JOINT_BOUND Combine weak/sub/partition-local bounds into L_new.

    if nargin < 5 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    n_window = height(window_table);
    rows = cell(n_window, 1);

    for i = 1:n_window
        values = [-inf, -inf, -inf];
        names = ["weak", "sub", "partblk"];
        valid_mask = false(1, 3);
        if cfg.stage11.enable_weak && weak_table.weak_valid(i)
            values(1) = weak_table.L_weak(i);
            valid_mask(1) = true;
        end
        if cfg.stage11.enable_sub && sub_table.sub_valid(i)
            values(2) = sub_table.L_sub(i);
            valid_mask(2) = true;
        end
        if cfg.stage11.enable_blk && blk_table.partblk_valid(i)
            values(3) = blk_table.L_partblk(i);
            valid_mask(3) = true;
        end

        if any(valid_mask)
            [L_new, idx_best] = max(values);
            new_valid = isfinite(L_new);
            Dg_new_window = L_new / cfg.stage11.gamma_G;
            best_source = string(names(idx_best));
        else
            L_new = NaN;
            Dg_new_window = NaN;
            best_source = "invalid";
            new_valid = false;
        end

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', window_table.row_id(i), ...
            'L_new', L_new, ...
            'Dg_new_window', Dg_new_window, ...
            'best_bound_source', best_source, ...
            'new_valid', new_valid);
    end

    joint_table = struct2table(vertcat(rows{:}));
end
