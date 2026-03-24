function hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg)
    %BUILD_HGV_CFG_FROM_CASE_STAGE02
    % Build HGV initial condition/configuration for one Stage02 case.
    %
    % Stage04G.4a:
    %   - geodetic entry point continues to come from Stage01 casebank
    %   - heading family now truly enters dynamics through sigma0
    %   - control profile is delegated to make_ctrl_profile_stage02()
    
        hgv_cfg = struct();
    
        % ------------------------------------------------------------
        % Basic initial scalars with safe fallbacks
        % ------------------------------------------------------------
        if isfield(cfg.stage02, 'v0_mps')
            hgv_cfg.v0 = cfg.stage02.v0_mps;
        else
            hgv_cfg.v0 = 5500.0;
        end
    
        if isfield(cfg.stage02, 'theta0_deg')
            theta0_deg = cfg.stage02.theta0_deg;
        else
            theta0_deg = 0.0;
        end
        hgv_cfg.theta0 = deg2rad(theta0_deg);
    
        if isfield(cfg.stage02, 'h0_m')
            h0_m_default = cfg.stage02.h0_m;
        else
            h0_m_default = 50000.0;
        end
    
        % ------------------------------------------------------------
        % Horizontal initial location:
        %   priority to Stage01 geodetic entry point
        % ------------------------------------------------------------
        if isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') ...
                && cfg.geo.enable_geodetic_anchor ...
                && isfield(case_i, 'entry_point_ecef_m') ...
                && all(isfinite(case_i.entry_point_ecef_m(:)))
    
            [lat_deg, lon_deg, ~] = ecef_to_geodetic(case_i.entry_point_ecef_m, cfg);
    
            hgv_cfg.phi0 = deg2rad(lat_deg);
            hgv_cfg.lambda0 = deg2rad(lon_deg);
            hgv_cfg.h0 = h0_m_default;
        else
            if isfield(cfg.stage02, 'phi0_deg')
                phi0_deg = cfg.stage02.phi0_deg;
            else
                phi0_deg = 0.0;
            end
    
            if isfield(cfg.stage02, 'lambda0_deg')
                lambda0_deg = cfg.stage02.lambda0_deg;
            else
                lambda0_deg = 0.0;
            end
    
            hgv_cfg.phi0 = deg2rad(phi0_deg);
            hgv_cfg.lambda0 = deg2rad(lambda0_deg);
            hgv_cfg.h0 = h0_m_default;
        end
    
        % ------------------------------------------------------------
        % Heading family -> sigma0
        %
        % Current Stage01 heading convention:
        %   heading_deg measured in local ENU x-y plot
        %   x = east, y = north
        %   0 deg   -> east
        %   90 deg  -> north
        %   180 deg -> west
        %
        % Current VTC sigma convention from dynamics:
        %   sigma = 0 deg   -> north
        %   sigma = -90 deg -> east
        %   sigma = +90 deg -> west
        %
        % Therefore:
        %   sigma0_deg = heading_deg - 90
        % ------------------------------------------------------------
        if isfield(case_i, 'heading_deg') && isfinite(case_i.heading_deg)
            sigma0_deg = wrapTo180(case_i.heading_deg - 90.0);
        elseif isfield(cfg.stage02, 'sigma0_deg')
            sigma0_deg = cfg.stage02.sigma0_deg;
        else
            sigma0_deg = 0.0;
        end
        hgv_cfg.sigma0 = deg2rad(sigma0_deg);
    
        % ------------------------------------------------------------
        % Open-loop control profile
        % ------------------------------------------------------------
        ctrl_profile = make_ctrl_profile_stage02(case_i, cfg);
        hgv_cfg.ctrl_profile = ctrl_profile;
    
        % ------------------------------------------------------------
        % Debug/meta fields
        % ------------------------------------------------------------
        hgv_cfg.debug = struct();
        hgv_cfg.debug.case_id = case_i.case_id;
        hgv_cfg.debug.family = case_i.family;
        hgv_cfg.debug.subfamily = case_i.subfamily;
    
        if isfield(case_i, 'heading_deg')
            hgv_cfg.debug.heading_deg = case_i.heading_deg;
        else
            hgv_cfg.debug.heading_deg = NaN;
        end
    
        if isfield(case_i, 'heading_offset_deg')
            hgv_cfg.debug.heading_offset_deg = case_i.heading_offset_deg;
        else
            hgv_cfg.debug.heading_offset_deg = NaN;
        end
    
        hgv_cfg.debug.sigma0_deg = sigma0_deg;
    
        if isfield(case_i, 'entry_point_enu_km')
            hgv_cfg.debug.entry_point_enu_km = case_i.entry_point_enu_km;
        end
        if isfield(case_i, 'entry_point_ecef_m')
            hgv_cfg.debug.entry_point_ecef_m = case_i.entry_point_ecef_m;
        end
    end