function r_enu_m = ecef_to_local_enu(r_ecef_m, lat0_deg, lon0_deg, h0_m, cfg_like)
%ECEF_TO_LOCAL_ENU Map ECEF coordinates to local ENU coordinates.
%
% Inputs:
%   r_ecef_m : 3xN or Nx3 ECEF coordinates [m]

    was_row_major = false;
    if size(r_ecef_m,1) ~= 3 && size(r_ecef_m,2) == 3
        r_ecef_m = r_ecef_m.';
        was_row_major = true;
    end
    assert(size(r_ecef_m,1) == 3, 'r_ecef_m must be 3xN or Nx3.');

    r0_ecef_m = geodetic_to_ecef(lat0_deg, lon0_deg, h0_m, cfg_like);

    % Normalize reference point to 3x1
    if isvector(r0_ecef_m)
        r0_ecef_m = r0_ecef_m(:);
    elseif size(r0_ecef_m,1) == 1 && size(r0_ecef_m,2) == 3
        r0_ecef_m = r0_ecef_m.';
    elseif size(r0_ecef_m,1) == 3 && size(r0_ecef_m,2) == 1
        % already fine
    elseif size(r0_ecef_m,1) == 1 && size(r0_ecef_m,2) == 1
        error('ecef_to_local_enu:InvalidReferencePoint', ...
            'Reference point conversion returned invalid size.');
    else
        % If geodetic_to_ecef returned Nx3 for scalar input unexpectedly, take first row
        if size(r0_ecef_m,2) == 3
            r0_ecef_m = r0_ecef_m(1,:).';
        else
            error('ecef_to_local_enu:InvalidReferencePoint', ...
                'Reference point conversion returned invalid size.');
        end
    end

    [~, R_ecef_to_enu] = enu_basis_from_geodetic(lat0_deg, lon0_deg);

    r_enu_m = R_ecef_to_enu * (r_ecef_m - r0_ecef_m);

    if was_row_major
        r_enu_m = r_enu_m.';
    end
end
