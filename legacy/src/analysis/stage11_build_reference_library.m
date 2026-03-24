function ref_library = stage11_build_reference_library(input_dataset, contrib_bank, cfg)
%STAGE11_BUILD_REFERENCE_LIBRARY Build multi-template reference libraries by group key.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    theta_mask = local_reference_theta_mask(WT, cfg.stage11.reference_theta);
    if ~any(theta_mask)
        theta_mask = true(height(WT), 1);
    end

    reference_rows = local_pick_reference_rows(WT, theta_mask, cfg);
    key_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for ir = 1:numel(reference_rows)
        row_idx = reference_rows(ir);
        J_list = contrib_bank(row_idx).J_list;
        J_meta = contrib_bank(row_idx).J_meta;
        if isempty(J_list)
            continue;
        end

        group_keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
        [group_values, ~, group_idx] = unique(group_keys, 'stable');
        for g = 1:numel(group_values)
            members = find(group_idx == g);
            J_hat = zeros(size(J_list{members(1)}));
            for m = 1:numel(members)
                J_hat = J_hat + J_list{members(m)};
            end
            J_hat = 0.5 * ((J_hat / numel(members)) + (J_hat / numel(members)).');

            key_str = char(group_values(g));
            template_entry = struct( ...
                'template', J_hat, ...
                'reference_row_id', WT.row_id(row_idx), ...
                'reference_case_id', string(WT.case_id(row_idx)), ...
                'reference_case_index', WT.case_index(row_idx), ...
                'reference_window_id', WT.window_id(row_idx), ...
                'reference_theta_id', WT.theta_id(row_idx), ...
                'group_key', string(group_values(g)));

            if isKey(key_map, key_str)
                bucket = key_map(key_str);
                bucket.templates{end+1,1} = template_entry.template; %#ok<AGROW>
                bucket.meta(end+1,1) = rmfield(template_entry, 'template'); %#ok<AGROW>
                bucket.reference_row_ids(end+1,1) = template_entry.reference_row_id; %#ok<AGROW>
                key_map(key_str) = bucket;
            else
                bucket = struct();
                bucket.group_key = string(group_values(g));
                bucket.templates = {template_entry.template};
                bucket.meta = rmfield(template_entry, 'template');
                bucket.reference_row_ids = template_entry.reference_row_id;
                key_map(key_str) = bucket;
            end
        end
    end

    map_keys = string(key_map.keys);
    map_values = values(key_map);
    buckets = vertcat(map_values{:});

    ref_library = struct();
    ref_library.reference_row_ids = reference_rows(:);
    ref_library.reference_case_id = string(unique(WT.case_id(reference_rows)));
    ref_library.reference_case_index = unique(WT.case_index(reference_rows));
    ref_library.reference_window_ids = WT.window_id(reference_rows).';
    ref_library.reference_theta_id = unique(WT.theta_id(reference_rows));
    ref_library.partition_keys = map_keys(:);
    ref_library.buckets = buckets;
    ref_library.note = "multi_window_reference_templates";
end


function rows = local_pick_reference_rows(WT, theta_mask, cfg)
    reference_case_id = string(cfg.stage11.reference_case_id);
    case_idx = min(max(1, cfg.stage11.reference_case_index), max(WT.case_index(theta_mask)));

    candidate_mask = theta_mask;
    if strlength(reference_case_id) > 0
        candidate_mask = candidate_mask & (string(WT.case_id) == reference_case_id);
    else
        candidate_mask = candidate_mask & (WT.case_index == case_idx);
    end
    candidate_rows = find(candidate_mask);
    if isempty(candidate_rows)
        candidate_rows = find(theta_mask);
    end
    if isempty(candidate_rows)
        error('Stage11 reference library found no candidate windows.');
    end

    switch lower(char(string(cfg.stage11.reference_window_mode)))
        case 'multi_fixed'
            requested = cfg.stage11.reference_window_indices;
            rows = zeros(0,1);
            for i = 1:numel(requested)
                row_match = candidate_rows(WT.window_id(candidate_rows) == requested(i));
                if ~isempty(row_match)
                    rows(end+1,1) = row_match(1); %#ok<AGROW>
                end
            end
            if isempty(rows)
                [~, order] = sort(abs(WT.window_id(candidate_rows) - cfg.stage11.reference_window_index), 'ascend');
                rows = candidate_rows(order(1:min(numel(candidate_rows), max(1, numel(requested)))));
            end
        otherwise
            error('Unsupported cfg.stage11.reference_window_mode: %s', string(cfg.stage11.reference_window_mode));
    end

    rows = unique(rows(:), 'stable');
end


function mask = local_reference_theta_mask(WT, reference_theta)
    theta_list = WT.theta_struct;
    mask = false(height(WT), 1);
    for i = 1:height(WT)
        th = theta_list(i);
        if iscell(th)
            th = th{1};
        end
        mask(i) = isequal(local_theta_signature(th), local_theta_signature(reference_theta));
    end
end


function sig = local_theta_signature(theta)
    sig = [theta.h_km, theta.i_deg, theta.P, theta.T, theta.F];
end


function keys_out = local_partition_keys(J_meta, partition_mode)
    n = numel(J_meta);
    keys_out = strings(n, 1);
    for i = 1:n
        switch lower(char(string(partition_mode)))
            case 'plane'
                keys_out(i) = "plane_" + string(J_meta(i).plane_id);
            case 'plane_phase'
                keys_out(i) = "plane_" + string(J_meta(i).plane_id) + "_phase_" + string(mod(J_meta(i).sat_id, 2));
            case 'geometry_tag'
                keys_out(i) = string(J_meta(i).geometry_tag);
            otherwise
                error('Unsupported partition_mode: %s', string(partition_mode));
        end
    end
end
