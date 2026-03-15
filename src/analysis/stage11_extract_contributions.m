function contrib_bank = stage11_extract_contributions(input_dataset, cfg)
%STAGE11_EXTRACT_CONTRIBUTIONS Extract per-window additive contributions J_alpha.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    detail_list = input_dataset.detail_list;
    n_window = height(WT);

    contrib_bank = repmat(struct( ...
        'row_id', 0, ...
        'J_list', {{}}, ...
        'J_meta', struct([]), ...
        'recon_error_fro', NaN, ...
        'recon_error_max_abs', NaN), n_window, 1);
    t_start = tic;

    for i = 1:n_window
        detail = detail_list{WT.detail_id(i)};
        vis_case = detail.vis_case;
        walker = detail.walker;
        satbank = detail.satbank;
        idx_start = WT.idx_start(i);
        idx_end = WT.idx_end(i);

        J_list = cell(0,1);
        meta_rows = cell(0,1);
        idx = 0;

        for k = idx_start:idx_end
            vis_idx = find(vis_case.visible_mask(k,:));
            n_vis = numel(vis_idx);
            if n_vis < 1
                continue;
            end
            geometry_tag = local_geometry_tag(n_vis);
            r_tgt = vis_case.r_tgt_eci_km(k,:);

            for jj = 1:n_vis
                s = vis_idx(jj);
                idx = idx + 1;
                J = info_increment_angle_stage04(satbank.r_eci_km(k,:,s), r_tgt, cfg);
                if cfg.stage11.force_symmetric
                    J = 0.5 * (J + J.');
                end
                J_list{idx,1} = J; %#ok<AGROW>
                meta_rows{idx,1} = struct( ... %#ok<AGROW>
                    'alpha_id', idx, ...
                    'plane_id', walker.sat(s).plane_id, ...
                    'sat_id', s, ...
                    'time_index', k, ...
                    't_s', vis_case.t_s(k), ...
                    'geometry_tag', string(geometry_tag), ...
                    'visible_count_at_t', n_vis);
            end
        end

        if isempty(J_list)
            Wrec = zeros(3,3);
            meta_struct = struct('alpha_id', {}, 'plane_id', {}, 'sat_id', {}, ...
                'time_index', {}, 't_s', {}, 'geometry_tag', {}, 'visible_count_at_t', {});
        else
            Wrec = zeros(size(J_list{1}));
            for j = 1:numel(J_list)
                Wrec = Wrec + J_list{j};
            end
            meta_struct = vertcat(meta_rows{:});
        end

        Wr = WT.Wr{i};
        if cfg.stage11.force_symmetric
            Wr = 0.5 * (Wr + Wr.');
        end
        D = Wr - Wrec;

        contrib_bank(i).row_id = WT.row_id(i);
        contrib_bank(i).J_list = J_list;
        contrib_bank(i).J_meta = meta_struct;
        contrib_bank(i).recon_error_fro = norm(D, 'fro');
        contrib_bank(i).recon_error_max_abs = max(abs(D(:)));

        if cfg.stage11.log_every_window
            fprintf(['[stage11][contrib] theta %d case %s window %d/%d row %d/%d elapsed=%.1fs', newline], ...
                WT.theta_id(i), char(string(WT.case_id(i))), WT.window_id(i), WT.window_count_full(i), ...
                WT.row_id(i), n_window, toc(t_start));
        end
    end
end


function tag = local_geometry_tag(n_vis)
    if n_vis <= 1
        tag = "single_visible";
    elseif n_vis == 2
        tag = "dual_visible";
    else
        tag = "multi_visible";
    end
end
