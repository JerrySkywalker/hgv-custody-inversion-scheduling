function Wr_t = build_time_info_series_stage04(vis_case, satbank, cfg)
    %BUILD_TIME_INFO_SERIES_STAGE04 Build per-time-step information increments for one case.

    assert(isfield(vis_case, 'r_tgt_eci_km'), ...
        'vis_case is missing r_tgt_eci_km. Stage04 expects ECI target geometry.');

    Nt = size(vis_case.r_tgt_eci_km, 1);
    Wr_t = zeros(Nt, 3, 3);

    sigma2 = cfg.stage04.sigma_angle_rad ^ 2;
    eps_reg = cfg.stage04.eps_reg;

    for k = 1:Nt
        visible_mask_k = vis_case.visible_mask(k,:);
        if ~any(visible_mask_k)
            continue;
        end

        r_tgt = vis_case.r_tgt_eci_km(k,:);
        sat_slice = satbank.r_eci_km(k, :, visible_mask_k);
        r_sat = reshape(sat_slice, 3, []).';

        Wr_t(k,:,:) = accumulate_visible_info_matrix_stage04(r_sat, r_tgt, sigma2, eps_reg);
    end
end
