function [lat2_deg, lon2_deg] = direct_geodesic_sphere(lat1_deg, lon1_deg, az_deg, s_m, R_m)
    %DIRECT_GEODESIC_SPHERE
    % Solve the direct geodesic problem on a sphere.
    %
    % Inputs:
    %   lat1_deg : start latitude [deg]
    %   lon1_deg : start longitude [deg]
    %   az_deg   : forward azimuth measured clockwise from north [deg]
    %   s_m      : surface distance [m]
    %   R_m      : sphere radius [m]
    %
    % Outputs:
    %   lat2_deg : destination latitude [deg]
    %   lon2_deg : destination longitude [deg]
    %
    % Notes:
    %   This is a spherical approximation, suitable for current Stage04G.3b.
    %   It is much more appropriate than tangent-plane linear mapping for
    %   1000-3000 km scale regional boundaries.
    
        lat1 = deg2rad(lat1_deg);
        lon1 = deg2rad(lon1_deg);
        az   = deg2rad(az_deg);
    
        delta = s_m / R_m;
    
        sin_lat1 = sin(lat1);
        cos_lat1 = cos(lat1);
        sin_delta = sin(delta);
        cos_delta = cos(delta);
    
        sin_lat2 = sin_lat1 .* cos_delta + cos_lat1 .* sin_delta .* cos(az);
        lat2 = asin(max(min(sin_lat2, 1), -1));
    
        y = sin(az) .* sin_delta .* cos_lat1;
        x = cos_delta - sin_lat1 .* sin(lat2);
        lon2 = lon1 + atan2(y, x);
    
        % wrap longitude to [-180, 180)
        lon2 = mod(lon2 + pi, 2*pi) - pi;
    
        lat2_deg = rad2deg(lat2);
        lon2_deg = rad2deg(lon2);
    end