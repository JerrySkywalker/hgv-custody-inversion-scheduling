function r_ecef_m = eci_to_ecef(r_eci_m, epoch_utc, dt_s)
    %ECI_TO_ECEF Convert ECI position(s) to ECEF using Earth rotation.
    %
    % Inputs:
    %   r_eci_m  : 3xN or Nx3 ECI coordinates [m]
    %   epoch_utc: reference epoch (string or datetime)
    %   dt_s     : scalar or 1xN time offset(s) [s]
    
        was_row_major = false;
        if size(r_eci_m,1) ~= 3 && size(r_eci_m,2) == 3
            r_eci_m = r_eci_m.';
            was_row_major = true;
        end
        assert(size(r_eci_m,1) == 3, 'r_eci_m must be 3xN or Nx3.');
    
        N = size(r_eci_m,2);
    
        if isscalar(dt_s)
            dt_s = repmat(dt_s, 1, N);
        else
            dt_s = reshape(dt_s, 1, []);
            assert(numel(dt_s) == N, 'dt_s must be scalar or match number of points.');
        end
    
        gmst0 = gmst_from_utc(epoch_utc);
        omega = 7.2921150e-5;  % rad/s
    
        r_ecef_m = zeros(size(r_eci_m));
        for k = 1:N
            theta = gmst0 + omega * dt_s(k);
            R3T = [ cos(theta),  sin(theta), 0; ...
                   -sin(theta),  cos(theta), 0; ...
                    0,           0,          1];
            r_ecef_m(:,k) = R3T * r_eci_m(:,k);
        end
    
        if was_row_major
            r_ecef_m = r_ecef_m.';
        end
    end