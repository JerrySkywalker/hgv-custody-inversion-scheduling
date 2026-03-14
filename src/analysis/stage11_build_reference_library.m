function ref_library = stage11_build_reference_library(input_dataset, contrib_bank, cfg)
%STAGE11_BUILD_REFERENCE_LIBRARY Build reference templates for partition cells.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    theta_mask = local_reference_theta_mask(WT, cfg.stage11.reference_theta);
    if ~any(theta_mask)
        theta_mask = true(height(WT), 1);
    end

    case_idx = min(max(1, cfg.stage11.reference_case_index), max(WT.case_index(theta_mask)));
    win_idx = cfg.stage11.reference_window_index;
    ref_mask = theta_mask & (WT.case_index == case_idx) & (WT.window_id == win_idx);
    if ~any(ref_mask)
        candidate_rows = find(theta_mask & (WT.case_index == case_idx));
        if isempty(candidate_rows)
            candidate_rows = find(theta_mask, 1, 'first');
        else
            [~, local_idx] = min(abs(WT.window_id(candidate_rows) - win_idx));
            candidate_rows = candidate_rows(local_idx);
        end
        ref_row = candidate_rows(1);
    else
        ref_row = find(ref_mask, 1, 'first');
    end

    J_list = contrib_bank(ref_row).J_list;
    J_meta = contrib_bank(ref_row).J_meta;
    keys = local_partition_keys(J_meta, cfg.stage11.partition_mode);
    [group_values, ~, group_idx] = unique(keys, 'stable');

    templates = cell(numel(group_values), 1);
    for g = 1:numel(group_values)
        members = find(group_idx == g);
        J_hat = zeros(size(J_list{members(1)}));
        for m = 1:numel(members)
            J_hat = J_hat + J_list{members(m)};
        end
        J_hat = J_hat / numel(members);
        templates{g} = 0.5 * (J_hat + J_hat.');
    end

    ref_library = struct();
    ref_library.reference_row_id = WT.row_id(ref_row);
    ref_library.reference_case_index = WT.case_index(ref_row);
    ref_library.reference_window_id = WT.window_id(ref_row);
    ref_library.reference_theta_id = WT.theta_id(ref_row);
    ref_library.partition_keys = group_values;
    ref_library.templates = templates;
    ref_library.note = "reference_window_templates";
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
