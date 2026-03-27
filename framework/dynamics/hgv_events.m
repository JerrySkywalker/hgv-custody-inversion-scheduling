function [value, isterminal, direction] = hgv_events(~, X, cfg, p)
    %hgv_events Unified event function for Stage02.
    
        v = X(1);
        phi = X(4);
        lambda = X(5);
        r = X(6);
    
        h_m = r - p.Re;
        [x_km, y_km] = geodetic_to_local_xy(phi, lambda, cfg);
        dist_to_center_km = hypot(x_km - cfg.stage01.disk_center_xy_km(1), ...
                                  y_km - cfg.stage01.disk_center_xy_km(2));
    
        value = [];
        isterminal = [];
        direction = [];
    
        % Minimum altitude
        value(end+1,1) = h_m - cfg.stage02.h_min_m;
        isterminal(end+1,1) = 1;
        direction(end+1,1) = -1;
    
        % Maximum altitude
        value(end+1,1) = cfg.stage02.h_max_m - h_m;
        isterminal(end+1,1) = 1;
        direction(end+1,1) = -1;
    
        % Minimum speed
        value(end+1,1) = v - cfg.stage02.v_min_mps;
        isterminal(end+1,1) = 1;
        direction(end+1,1) = -1;
    
        % Maximum speed
        value(end+1,1) = cfg.stage02.v_max_mps - v;
        isterminal(end+1,1) = 1;
        direction(end+1,1) = -1;
    
        % Task capture radius
        if cfg.stage02.enable_task_capture_event
            value(end+1,1) = dist_to_center_km - cfg.stage02.capture_radius_km;
            isterminal(end+1,1) = 1;
            direction(end+1,1) = -1;
        end
    
        % Optional landing event
        if cfg.stage02.enable_landing_event
            value(end+1,1) = h_m;  % h = 0
            isterminal(end+1,1) = 1;
            direction(end+1,1) = -1;
        end
    end

