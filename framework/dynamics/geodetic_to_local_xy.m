function [x_km, y_km] = geodetic_to_local_xy(phi_rad, lambda_rad, cfg)
    %geodetic_to_local_xy
    % Convert geodetic latitude/longitude (rad) back to local tangent-plane (km).
    
        Re = cfg.target_template.planet.re_m;
        phi_ref = deg2rad(cfg.target_template.reference.phi_ref_deg);
        lambda_ref = deg2rad(cfg.target_template.reference.lambda_ref_deg);
    
        y_m = (phi_rad - phi_ref) * Re;
        x_m = (lambda_rad - lambda_ref) * Re * cos(phi_ref);
    
        x_km = x_m / 1000;
        y_km = y_m / 1000;
    end


