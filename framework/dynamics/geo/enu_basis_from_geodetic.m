function [R_enu_to_ecef, R_ecef_to_enu] = enu_basis_from_geodetic(lat_deg, lon_deg)
    %ENU_BASIS_FROM_GEODETIC Build ENU <-> ECEF rotation matrices.
    %
    % ENU basis:
    %   x_e = East
    %   y_n = North
    %   z_u = Up
    
        lat = deg2rad(lat_deg);
        lon = deg2rad(lon_deg);
    
        sin_lat = sin(lat);
        cos_lat = cos(lat);
        sin_lon = sin(lon);
        cos_lon = cos(lon);
    
        % Columns are unit vectors of ENU expressed in ECEF
        e_hat = [-sin_lon;            cos_lon;           0];
        n_hat = [-sin_lat*cos_lon;   -sin_lat*sin_lon;   cos_lat];
        u_hat = [ cos_lat*cos_lon;    cos_lat*sin_lon;   sin_lat];
    
        R_enu_to_ecef = [e_hat, n_hat, u_hat];
        R_ecef_to_enu = R_enu_to_ecef.';
    end
