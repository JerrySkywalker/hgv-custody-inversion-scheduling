function blk_table = stage11_compute_block_bound(contrib_bank, input_dataset, cfg)
%STAGE11_COMPUTE_BLOCK_BOUND Compute a conservative block-style lower bound.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    n_window = height(WT);
    rows = cell(n_window, 1);

    for i = 1:n_window
        J_list = contrib_bank(i).J_list;
        J_meta = contrib_bank(i).J_meta;
        if isempty(J_list)
            ell_i = 0;
            r_i = 0;
            L_blk = 0;
            block_count = 0;
        else
            keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
            [group_values, ~, group_idx] = unique(keys, 'stable');
            block_count = numel(group_values);
            block_mats = cell(block_count, 1);
            ell = zeros(block_count, 1);
            rad = zeros(block_count, 1);
            block_norm = zeros(block_count, 1);

            for g = 1:block_count
                members = find(group_idx == g);
                B = zeros(size(J_list{1}));
                for m = 1:numel(members)
                    B = B + J_list{members(m)};
                end
                B = 0.5 * (B + B.');
                block_mats{g} = B;
                ell(g) = min(real(eig(B)));
                block_norm(g) = norm(B, 2);
            end

            for g = 1:block_count
                rad(g) = sum(block_norm) - block_norm(g);
            end

            ell_i = min(ell);
            r_i = max(rad);
            L_blk = min(ell - rad);
        end

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'block_count', block_count, ...
            'ell_i', ell_i, ...
            'r_i', r_i, ...
            'L_blk', L_blk, ...
            'blk_valid', WT.truth_lambda_min(i) + 1e-9 >= L_blk);
    end

    blk_table = struct2table(vertcat(rows{:}));
end


function keys = local_partition_keys(J_meta, partition_mode)
    n = numel(J_meta);
    keys = strings(n, 1);
    for i = 1:n
        switch lower(char(string(partition_mode)))
            case 'plane'
                keys(i) = "plane_" + string(J_meta(i).plane_id);
            case 'plane_phase'
                keys(i) = "plane_" + string(J_meta(i).plane_id) + "_phase_" + string(mod(J_meta(i).sat_id, 2));
            case 'geometry_tag'
                keys(i) = string(J_meta(i).geometry_tag);
            otherwise
                error('Unsupported partition_mode: %s', string(partition_mode));
        end
    end
end
