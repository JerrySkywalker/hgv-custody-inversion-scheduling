function r_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, cfg)
    %GEODETIC_TO_ECEF Convert geodetic coordinates to ECEF position [m].
    %
    % Inputs:
    %   lat_deg : geodetic latitude [deg]
    %   lon_deg : longitude [deg]
    %   h_m     : ellipsoidal height [m]
    %   cfg     : config struct containing cfg.geo.a_m and cfg.geo.e2
    %
    % Output:
    %   r_ecef_m : 3x1 ECEF position [m]
    
        lat = deg2rad(lat_deg);
        lon = deg2rad(lon_deg);
    
        a  = cfg.geo.a_m;
        e2 = cfg.geo.e2;
    
        sin_lat = sin(lat);
        cos_lat = cos(lat);
        sin_lon = sin(lon);
        cos_lon = cos(lon);
    
        N = a / sqrt(1 - e2 * sin_lat^2);
    
        x = (N + h_m) * cos_lat * cos_lon;
        y = (N + h_m) * cos_lat * sin_lon;
        z = (N * (1 - e2) + h_m) * sin_lat;
    
        r_ecef_m = [x; y; z];
    end