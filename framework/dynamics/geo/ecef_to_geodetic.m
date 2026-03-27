function [lat_deg, lon_deg, h_m] = ecef_to_geodetic(r_ecef_m, cfg)
    %ECEF_TO_GEODETIC Convert ECEF position(s) to geodetic coordinates.
    %
    % Inputs:
    %   r_ecef_m : 3xN or Nx3 ECEF position(s) [m]
    %   cfg      : config containing WGS84 parameters in cfg.geo
    %
    % Outputs:
    %   lat_deg  : geodetic latitude [deg]
    %   lon_deg  : longitude [deg]
    %   h_m      : ellipsoidal height [m]
    %
    % Notes:
    %   Uses a standard iterative solution, sufficient for current stage.
    
        was_row_major = false;
        if size(r_ecef_m,1) ~= 3 && size(r_ecef_m,2) == 3
            r_ecef_m = r_ecef_m.';
            was_row_major = true;
        end
        assert(size(r_ecef_m,1) == 3, 'r_ecef_m must be 3xN or Nx3.');
    
        a  = cfg.geo.a_m;
        e2 = cfg.geo.e2;
    
        x = r_ecef_m(1,:);
        y = r_ecef_m(2,:);
        z = r_ecef_m(3,:);
    
        lon = atan2(y, x);
        p = sqrt(x.^2 + y.^2);
    
        % initial guess
        lat = atan2(z, p .* (1 - e2));
        h = zeros(size(lat));
    
        for k = 1:10
            sin_lat = sin(lat);
            N = a ./ sqrt(1 - e2 .* sin_lat.^2);
            h = p ./ cos(lat) - N;
            lat_new = atan2(z, p .* (1 - e2 .* N ./ (N + h)));
            if max(abs(lat_new - lat)) < 1e-12
                lat = lat_new;
                break;
            end
            lat = lat_new;
        end
    
        lat_deg = rad2deg(lat);
        lon_deg = rad2deg(lon);
        h_m = h;
    
        if was_row_major
            lat_deg = lat_deg.';
            lon_deg = lon_deg.';
            h_m = h_m.';
        end
    end
