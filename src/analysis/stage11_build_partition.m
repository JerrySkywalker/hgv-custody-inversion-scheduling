function weak_table = stage11_build_partition(input_dataset, contrib_bank, cfg)
%STAGE11_BUILD_PARTITION Build weak-symmetry partition and L_weak.

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
        Wr = WT.Wr{i};
        if cfg.stage11.force_symmetric
            Wr = 0.5 * (Wr + Wr.');
        end

        if isempty(J_list)
            W_pi = zeros(size(Wr));
            eps_pi = 0;
            L_weak = 0;
            group_count = 0;
            partition_keys = "";
        else
            keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
            [group_values, ~, group_idx] = unique(keys, 'stable');
            group_count = numel(group_values);
            W_pi = zeros(size(Wr));
            eps_pi = 0;

            for g = 1:group_count
                members = find(group_idx == g);
                J_hat = local_representative(J_list(members), cfg.stage11.partition_rep);
                delta_g = 0;
                for m = 1:numel(members)
                    delta_g = max(delta_g, norm(J_list{members(m)} - J_hat, 2));
                end
                W_pi = W_pi + numel(members) * J_hat;
                eps_pi = eps_pi + numel(members) * delta_g;
            end

            W_pi = 0.5 * (W_pi + W_pi.');
            L_weak = min(real(eig(W_pi))) - eps_pi;
            partition_keys = string(strjoin(cellstr(group_values), '|'));
        end

        truth_lambda = WT.truth_lambda_min(i);
        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'group_count', group_count, ...
            'partition_keys', partition_keys, ...
            'eps_pi', eps_pi, ...
            'W_pi', {W_pi}, ...
            'lambda_min_W_pi', min(real(eig(0.5 * (W_pi + W_pi.')))), ...
            'L_weak', L_weak, ...
            'weak_valid', truth_lambda + 1e-9 >= L_weak);
    end

    weak_table = struct2table(vertcat(rows{:}));
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


function J_hat = local_representative(J_group, rep_mode)
    switch lower(char(string(rep_mode)))
        case 'mean'
            J_hat = zeros(size(J_group{1}));
            for i = 1:numel(J_group)
                J_hat = J_hat + J_group{i};
            end
            J_hat = J_hat / numel(J_group);
        otherwise
            error('Unsupported partition_rep: %s', string(rep_mode));
    end
    J_hat = 0.5 * (J_hat + J_hat.');
end
