function r_ecef_m = local_enu_to_ecef(r_enu_m, lat0_deg, lon0_deg, h0_m, cfg)
    %LOCAL_ENU_TO_ECEF Map local ENU coordinates to ECEF.
    %
    % Inputs:
    %   r_enu_m  : 3xN or Nx3 local ENU coordinates [m]
    %   lat0_deg : anchor latitude [deg]
    %   lon0_deg : anchor longitude [deg]
    %   h0_m     : anchor height [m]
    
        was_row_major = false;
        if size(r_enu_m,1) ~= 3 && size(r_enu_m,2) == 3
            r_enu_m = r_enu_m.';
            was_row_major = true;
        end
        assert(size(r_enu_m,1) == 3, 'r_enu_m must be 3xN or Nx3.');
    
        r0_ecef_m = geodetic_to_ecef(lat0_deg, lon0_deg, h0_m, cfg);
        [R_enu_to_ecef, ~] = enu_basis_from_geodetic(lat0_deg, lon0_deg);
    
        r_ecef_m = r0_ecef_m + R_enu_to_ecef * r_enu_m;
    
        if was_row_major
            r_ecef_m = r_ecef_m.';
        end
    end