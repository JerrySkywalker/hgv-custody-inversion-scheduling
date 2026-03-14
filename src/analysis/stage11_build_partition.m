function weak_table = stage11_build_partition(input_dataset, contrib_bank, ref_library, cfg)
%STAGE11_BUILD_PARTITION Build weak-symmetry partition and L_weak.

    if nargin < 4 || isempty(cfg)
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
            eta_pi = 0;
            L_weak = 0;
            group_count = 0;
            partition_keys = "";
            rep_source_used = "empty";
            reference_key_coverage = 0;
            partition_valid = false;
        else
            keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
            [group_values, ~, group_idx] = unique(keys, 'stable');
            group_count = numel(group_values);
            W_pi = zeros(size(Wr));
            eps_pi = 0;
            used_sources = strings(group_count, 1);
            n_ref_key = 0;
            partition_valid = true;

            for g = 1:group_count
                members = find(group_idx == g);
                [J_hat, source_token] = local_get_reference_template( ...
                    group_values(g), i, input_dataset, contrib_bank, ref_library, cfg);
                used_sources(g) = source_token;
                if source_token == "reference_library"
                    n_ref_key = n_ref_key + 1;
                end
                if isempty(J_hat)
                    partition_valid = false;
                    continue;
                end
                delta_g = 0;
                for m = 1:numel(members)
                    delta_g = max(delta_g, norm(J_list{members(m)} - J_hat, 2));
                end
                W_pi = W_pi + numel(members) * J_hat;
                eps_pi = eps_pi + numel(members) * delta_g;
            end

            W_pi = 0.5 * (W_pi + W_pi.');
            if partition_valid
                L_weak = min(real(eig(W_pi))) - eps_pi;
            else
                L_weak = NaN;
            end
            partition_keys = string(strjoin(cellstr(group_values), '|'));
            eta_pi = norm(Wr - W_pi, 'fro') / (norm(Wr, 'fro') + eps);
            reference_key_coverage = n_ref_key / max(group_count, 1);
            rep_source_used = local_reduce_sources(used_sources, partition_valid);
        end

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'group_count', group_count, ...
            'partition_keys', partition_keys, ...
            'eps_pi', eps_pi, ...
            'W_pi', {W_pi}, ...
            'eta_pi', eta_pi, ...
            'rep_source_used', string(rep_source_used), ...
            'reference_key_coverage', reference_key_coverage, ...
            'partition_valid', partition_valid, ...
            'lambda_min_W_pi', min(real(eig(0.5 * (W_pi + W_pi.')))), ...
            'L_weak', L_weak, ...
            'weak_valid', partition_valid && isfinite(L_weak));
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


function [J_hat, source_token] = local_get_reference_template(key_value, row_index, input_dataset, contrib_bank, ref_library, cfg)
    J_hat = [];
    source_token = "invalid";

    ref_idx = find(ref_library.partition_keys == key_value, 1, 'first');
    ref_row_matches_current = (ref_library.reference_row_id == input_dataset.window_table.row_id(row_index));
    if ~isempty(ref_idx) && ~ref_row_matches_current
        J_hat = ref_library.templates{ref_idx};
        source_token = "reference_library";
        return;
    end

    if strcmpi(char(string(cfg.stage11.reference_fallback)), 'leave_one_out')
        [J_hat, ok] = local_leave_one_out_template(key_value, row_index, input_dataset, contrib_bank, cfg.stage11.partition_mode);
        if ok
            source_token = "leave_one_out";
            return;
        end
    end
end


function [J_hat, ok] = local_leave_one_out_template(key_value, row_index, input_dataset, contrib_bank, partition_mode)
    WT = input_dataset.window_table;
    theta_id = WT.theta_id(row_index);
    J_hat = [];
    ok = false;

    acc = [];
    n = 0;
    for r = 1:numel(contrib_bank)
        if WT.theta_id(r) ~= theta_id || WT.row_id(r) == WT.row_id(row_index)
            continue;
        end
        J_meta_r = contrib_bank(r).J_meta;
        if isempty(J_meta_r)
            continue;
        end
        keys_r = local_partition_keys(J_meta_r, partition_mode);
        match_idx = find(keys_r == key_value);
        for j = 1:numel(match_idx)
            J = contrib_bank(r).J_list{match_idx(j)};
            if isempty(acc)
                acc = zeros(size(J));
            end
            acc = acc + J;
            n = n + 1;
        end
    end

    if n < 1
        return;
    end

    J_hat = 0.5 * ((acc / n) + (acc / n).');
    ok = true;
end


function token = local_reduce_sources(used_sources, partition_valid)
    if ~partition_valid
        token = "invalid";
        return;
    end
    used_sources = used_sources(strlength(used_sources) > 0);
    if isempty(used_sources)
        token = "invalid";
    elseif all(used_sources == used_sources(1))
        token = used_sources(1);
    else
        token = "mixed";
    end
end
