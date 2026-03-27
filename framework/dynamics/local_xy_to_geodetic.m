function [phi_rad, lambda_rad] = local_xy_to_geodetic(x_km, y_km, cfg)
    %local_xy_to_geodetic
    % Convert abstract local tangent-plane coordinates (km) to geodetic
    % latitude/longitude (rad) around a reference origin.
    
        Re = cfg.stage02.Re_m;
        phi_ref = deg2rad(cfg.stage02.phi_ref_deg);
        lambda_ref = deg2rad(cfg.stage02.lambda_ref_deg);
    
        x_m = x_km * 1000;
        y_m = y_km * 1000;
    
        phi_rad = phi_ref + y_m / Re;
        lambda_rad = lambda_ref + x_m / (Re * cos(phi_ref));
    end

