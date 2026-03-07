function hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg)
    %BUILD_HGV_CFG_FROM_CASE_STAGE02
    % Map Stage01 scenario case to VTC-HGV initial condition + control template.
    
        % Entry point in local frame -> geodetic
        x0_km = case_i.entry_point_xy_km(1);
        y0_km = case_i.entry_point_xy_km(2);
        [phi0_rad, lambda0_rad] = local_xy_to_geodetic_stage02(x0_km, y0_km, cfg);
    
        % Stage01 heading convention:
        %   psi = atan2d(y, x), 0 deg = +x (east), 90 deg = +y (north)
        % Old VTC sigma convention:
        %   sigma = 0 deg -> north
        %   sigma = -90 deg -> east
        psi_deg = case_i.heading_deg;
        sigma0_deg = psi_deg - 90.0;
    
        ctrl = make_ctrl_profile_stage02(case_i, cfg);
    
        hgv_cfg = struct();
        hgv_cfg.case_id = case_i.case_id;
        hgv_cfg.family = case_i.family;
        hgv_cfg.subfamily = case_i.subfamily;
    
        hgv_cfg.v0 = cfg.stage02.v0_mps;
        hgv_cfg.h0 = cfg.stage02.h0_m;
        hgv_cfg.theta0 = deg2rad(cfg.stage02.theta0_deg);
        hgv_cfg.sigma0 = deg2rad(sigma0_deg);
        hgv_cfg.phi0 = phi0_rad;
        hgv_cfg.lambda0 = lambda0_rad;
    
        % Keep old naming at interface to old dynamics
        hgv_cfg.alpha_deg = ctrl.alpha_deg;
        hgv_cfg.gamma_deg = ctrl.bank_deg;  % map bank -> old gamma name
    
        % Also preserve explicit profile metadata
        hgv_cfg.ctrl_profile = ctrl;
    end