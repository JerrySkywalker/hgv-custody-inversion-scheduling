function Wr = build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg)
    %BUILD_WINDOW_INFO_MATRIX_STAGE04
    % Build windowed information matrix Wr for one case and one window.
    %
    % Stage04G.6:
    %   - explicitly uses target/satellite ECI coordinates
    %   - remains angle-only geometric information accumulation
    
        assert(isfield(vis_case, 'r_tgt_eci_km'), ...
            'vis_case is missing r_tgt_eci_km. Stage04G.6 expects ECI target geometry.');
    
        Wr = zeros(3,3);
        eye3 = eye(3);
        sigma2 = cfg.stage04.sigma_angle_rad ^ 2;
        eps_reg = cfg.stage04.eps_reg;

        for k = idx_start:idx_end
            visible_mask_k = vis_case.visible_mask(k,:);
            if ~any(visible_mask_k)
                continue;
            end

            r_tgt = vis_case.r_tgt_eci_km(k,:);
            r_sat = local_extract_visible_sat_positions(satbank.r_eci_km, k, visible_mask_k);

            los = r_sat - r_tgt;
            rho2 = sum(los.^2, 2);

            valid = isfinite(rho2) & (rho2 > 0);
            if ~any(valid)
                continue;
            end

            los = los(valid, :);
            rho2 = rho2(valid);

            alpha = 1 ./ (sigma2 * rho2 + eps_reg);
            beta = alpha ./ rho2;

            Wr = Wr + sum(alpha) * eye3 - los.' * (los .* beta);
        end
    end

function r_sat = local_extract_visible_sat_positions(r_eci_km, time_index, visible_mask)
    sat_slice = r_eci_km(time_index, :, visible_mask);
    r_sat = reshape(sat_slice, 3, []).';
end
