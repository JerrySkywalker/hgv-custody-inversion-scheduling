function Wr = build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg)
    %BUILD_WINDOW_INFO_MATRIX_STAGE04
    % Build windowed information matrix Wr for one case and one window.
    
        Wr = zeros(3,3);
    
        for k = idx_start:idx_end
            r_tgt = vis_case.r_tgt_eci_km(k,:);
    
            vis_idx = find(vis_case.visible_mask(k,:));
            if isempty(vis_idx)
                continue;
            end
    
            for j = 1:numel(vis_idx)
                s = vis_idx(j);
                r_sat = satbank.r_eci_km(k,:,s);
                Q = info_increment_angle_stage04(r_sat, r_tgt, cfg);
                Wr = Wr + Q;
            end
        end
    end