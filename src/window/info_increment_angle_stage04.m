function Q = info_increment_angle_stage04(r_sat_km, r_tgt_km, cfg)
    %INFO_INCREMENT_ANGLE_STAGE04
    % Angle-only geometric information increment for target position.
    %
    % Q = (1 / (sigma^2 * rho^2)) * (I - u*u')
    % where u is LOS unit vector and rho is range.
    
        sigma = cfg.stage04.sigma_angle_rad;
    
        los = (r_sat_km(:) - r_tgt_km(:));
        rho = norm(los);
    
        if rho <= 0 || ~isfinite(rho)
            Q = zeros(3,3);
            return;
        end
    
        u = los / rho;
        P_perp = eye(3) - (u * u.');
    
        Q = (1 / (sigma^2 * rho^2 + cfg.stage04.eps_reg)) * P_perp;
    end