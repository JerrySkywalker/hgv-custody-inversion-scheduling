function weak_table = stage11_build_partition(input_dataset, contrib_bank, ref_library, cfg)
%STAGE11_BUILD_PARTITION Build weak-symmetry partition with template matching and fallback.

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
            row = local_empty_row(WT.row_id(i), Wr);
            rows{i,1} = row;
            continue;
        end

        group_keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
        [group_values, ~, group_idx] = unique(group_keys, 'stable');
        group_count = numel(group_values);
        W_pi = zeros(size(Wr));
        eps_pi = 0;
        used_sources = strings(group_count, 1);
        status_list = strings(group_count, 1);
        residual_list = nan(group_count, 1);
        matched_keys = strings(0,1);
        missing_keys = strings(0,1);
        fallback_keys = strings(0,1);
        n_groups_matched = 0;
        n_groups_fallback = 0;
        fully_supported = true;

        for g = 1:group_count
            members = find(group_idx == g);
            J_bar = local_group_mean(J_list, members);
            [J_hat, source_token, status_token, residual_min] = local_get_group_template( ...
                group_values(g), J_bar, WT.row_id(i), ref_library, cfg);
            used_sources(g) = source_token;
            status_list(g) = status_token;
            residual_list(g) = residual_min;

            if status_token == "matched"
                matched_keys(end+1,1) = group_values(g); %#ok<AGROW>
                n_groups_matched = n_groups_matched + 1;
            elseif status_token == "fallback_zero"
                fallback_keys(end+1,1) = group_values(g); %#ok<AGROW>
                n_groups_fallback = n_groups_fallback + 1;
            else
                missing_keys(end+1,1) = group_values(g); %#ok<AGROW>
                fully_supported = false;
            end

            if isempty(J_hat)
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
        lambda_min_Wpi = min(real(eig(W_pi)));
        supported_ratio = (n_groups_matched + n_groups_fallback) / max(group_count, 1);
        reference_match_ratio = n_groups_matched / max(group_count, 1);
        has_reference_match = n_groups_matched > 0;
        partition_valid = fully_supported;
        if partition_valid
            L_weak = lambda_min_Wpi - eps_pi;
        else
            L_weak = NaN;
        end
        rho_pi = eps_pi / (abs(lambda_min_Wpi) + eps);
        eta_pi = norm(Wr - W_pi, 'fro') / (norm(Wr, 'fro') + eps);

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'group_count', group_count, ...
            'n_groups_total', group_count, ...
            'n_groups_matched', n_groups_matched, ...
            'n_groups_fallback', n_groups_fallback, ...
            'match_ratio', reference_match_ratio, ...
            'reference_match_ratio', reference_match_ratio, ...
            'supported_ratio', supported_ratio, ...
            'fully_supported', fully_supported, ...
            'has_reference_match', has_reference_match, ...
            'partition_keys', string(strjoin(cellstr(group_values), '|')), ...
            'group_keys', string(strjoin(cellstr(group_values), '|')), ...
            'matched_group_keys', string(strjoin(cellstr(matched_keys), '|')), ...
            'missing_group_keys', string(strjoin(cellstr(missing_keys), '|')), ...
            'fallback_group_keys', string(strjoin(cellstr(fallback_keys), '|')), ...
            'group_status_list', string(strjoin(cellstr(status_list), '|')), ...
            'template_residual_min_list', {residual_list}, ...
            'eps_pi', eps_pi, ...
            'W_pi', {W_pi}, ...
            'eta_pi', eta_pi, ...
            'rep_source_used', string(local_reduce_sources(used_sources, fully_supported)), ...
            'reference_key_coverage', reference_match_ratio, ...
            'partition_valid', partition_valid, ...
            'lambda_min_W_pi', lambda_min_Wpi, ...
            'lambda_min_Wpi', lambda_min_Wpi, ...
            'rho_pi', rho_pi, ...
            'L_weak', L_weak, ...
            'weak_valid', fully_supported && isfinite(L_weak));
    end

    weak_table = struct2table(vertcat(rows{:}));
end


function row = local_empty_row(row_id, Wr)
    lambda_min_Wpi = min(real(eig(0.5 * (Wr*0 + (Wr*0).'))));
    row = struct( ...
        'row_id', row_id, ...
        'group_count', 0, ...
        'n_groups_total', 0, ...
        'n_groups_matched', 0, ...
        'n_groups_fallback', 0, ...
        'match_ratio', 0, ...
        'reference_match_ratio', 0, ...
        'supported_ratio', 0, ...
        'fully_supported', false, ...
        'has_reference_match', false, ...
        'partition_keys', "", ...
        'group_keys', "", ...
        'matched_group_keys', "", ...
        'missing_group_keys', "", ...
        'fallback_group_keys', "", ...
        'group_status_list', "", ...
        'template_residual_min_list', {nan(0,1)}, ...
        'eps_pi', 0, ...
        'W_pi', {zeros(size(Wr))}, ...
        'eta_pi', 0, ...
        'rep_source_used', "empty", ...
        'reference_key_coverage', 0, ...
        'partition_valid', false, ...
        'lambda_min_W_pi', lambda_min_Wpi, ...
        'lambda_min_Wpi', lambda_min_Wpi, ...
        'rho_pi', 0, ...
        'L_weak', NaN, ...
        'weak_valid', false);
end


function J_bar = local_group_mean(J_list, members)
    J_bar = zeros(size(J_list{members(1)}));
    for m = 1:numel(members)
        J_bar = J_bar + J_list{members(m)};
    end
    J_bar = 0.5 * ((J_bar / numel(members)) + (J_bar / numel(members)).');
end


function [J_hat, source_token, status_token, residual_min] = local_get_group_template(key_value, J_bar, current_row_id, ref_library, cfg)
    J_hat = [];
    source_token = "invalid";
    status_token = "unsupported";
    residual_min = NaN;

    bucket_idx = find(ref_library.partition_keys == key_value, 1, 'first');
    if ~isempty(bucket_idx)
        bucket = ref_library.buckets(bucket_idx);
        candidate_templates = {};
        for i = 1:numel(bucket.templates)
            if bucket.reference_row_ids(i) == current_row_id
                continue;
            end
            candidate_templates{end+1,1} = bucket.templates{i}; %#ok<AGROW>
        end
        if ~isempty(candidate_templates)
            switch lower(char(string(cfg.stage11.reference_select_mode)))
                case 'nearest_fro'
                    residuals = zeros(numel(candidate_templates), 1);
                    for i = 1:numel(candidate_templates)
                        residuals(i) = norm(J_bar - candidate_templates{i}, 'fro');
                    end
                    [residual_min, idx_best] = min(residuals);
                    J_hat = candidate_templates{idx_best};
                    source_token = "reference_library";
                    status_token = "matched";
                    return;
                otherwise
                    error('Unsupported cfg.stage11.reference_select_mode: %s', string(cfg.stage11.reference_select_mode));
            end
        end
    end

    switch lower(char(string(cfg.stage11.unmatched_group_mode)))
        case 'zero_fallback'
            J_hat = zeros(size(J_bar));
            residual_min = norm(J_bar, 'fro');
            source_token = "zero_fallback";
            status_token = "fallback_zero";
        case 'invalid'
            J_hat = [];
            residual_min = NaN;
            source_token = "invalid";
            status_token = "unsupported";
        otherwise
            error('Unsupported cfg.stage11.unmatched_group_mode: %s', string(cfg.stage11.unmatched_group_mode));
    end
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


function token = local_reduce_sources(used_sources, fully_supported)
    if ~fully_supported
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
