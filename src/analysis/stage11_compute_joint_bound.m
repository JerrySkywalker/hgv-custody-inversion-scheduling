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

        has_reference_match = false;
        match_ratio = nan;
        weak_valid = false;
        sub_valid = false;
        partblk_valid = false;
        if ismember('has_reference_match', weak_table.Properties.VariableNames)
            has_reference_match = logical(weak_table.has_reference_match(i));
        end
        if ismember('match_ratio', weak_table.Properties.VariableNames)
            match_ratio = weak_table.match_ratio(i);
        end
        supported_ratio = nan;
        fully_supported = false;
        if ismember('supported_ratio', weak_table.Properties.VariableNames)
            supported_ratio = weak_table.supported_ratio(i);
        end
        if ismember('fully_supported', weak_table.Properties.VariableNames)
            fully_supported = logical(weak_table.fully_supported(i));
        else
            fully_supported = isfinite(supported_ratio) && supported_ratio >= 1;
        end
        if ismember('weak_valid', weak_table.Properties.VariableNames)
            weak_valid = logical(weak_table.weak_valid(i));
        end
        if ismember('sub_valid', sub_table.Properties.VariableNames)
            sub_valid = logical(sub_table.sub_valid(i));
        end
        if ismember('partblk_valid', blk_table.Properties.VariableNames)
            partblk_valid = logical(blk_table.partblk_valid(i));
        end

        new_valid = fully_supported && isfinite(L_new) && ~isnan(L_new);
        if ~new_valid
            Dg_new_window = NaN;
            if ~any(valid_mask)
                best_source = "invalid";
            end
        end

        new_failure_reason = local_failure_reason(new_valid, fully_supported, weak_valid, sub_valid, partblk_valid, ...
            [L_new, Dg_new_window, values(valid_mask)]);

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', window_table.row_id(i), ...
            'L_new', L_new, ...
            'Dg_new_window', Dg_new_window, ...
            'best_bound_source', best_source, ...
            'new_valid', new_valid, ...
            'supported_ratio', supported_ratio, ...
            'fully_supported', fully_supported, ...
            'new_failure_reason', new_failure_reason);
    end

    joint_table = struct2table(vertcat(rows{:}));
end


function reason = local_failure_reason(new_valid, fully_supported, weak_valid, sub_valid, partblk_valid, numeric_values)
    if new_valid
        reason = "ok";
        return;
    end

    if ~fully_supported
        reason = "reference_gap";
        return;
    end
    if ~weak_valid && ~sub_valid && ~partblk_valid
        reason = "all_bounds_invalid";
        return;
    end
    if ~sub_valid
        reason = "sub_invalid";
        return;
    end
    if ~weak_valid
        reason = "weak_invalid";
        return;
    end
    if any(~isfinite(numeric_values))
        reason = "numerical_issue";
        return;
    end
    reason = "numerical_issue";
end
