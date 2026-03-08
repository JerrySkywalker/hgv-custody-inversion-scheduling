function r_eci_m = ecef_to_eci(r_ecef_m, epoch_utc, dt_s)
    %ECEF_TO_ECI Convert ECEF position(s) to ECI using Earth rotation.
    %
    % Inputs:
    %   r_ecef_m : 3xN or Nx3 ECEF coordinates [m]
    %   epoch_utc: reference epoch (string or datetime)
    %   dt_s     : scalar or 1xN time offset(s) [s]
    %
    % Notes:
    %   Uses a simple Earth-spin / GMST model suitable for current stage.
    
        was_row_major = false;
        if size(r_ecef_m,1) ~= 3 && size(r_ecef_m,2) == 3
            r_ecef_m = r_ecef_m.';
            was_row_major = true;
        end
        assert(size(r_ecef_m,1) == 3, 'r_ecef_m must be 3xN or Nx3.');
    
        N = size(r_ecef_m,2);
    
        if isscalar(dt_s)
            dt_s = repmat(dt_s, 1, N);
        else
            dt_s = reshape(dt_s, 1, []);
            assert(numel(dt_s) == N, 'dt_s must be scalar or match number of points.');
        end
    
        gmst0 = gmst_from_utc(epoch_utc);
        omega = 7.2921150e-5;  % rad/s
    
        r_eci_m = zeros(size(r_ecef_m));
        for k = 1:N
            theta = gmst0 + omega * dt_s(k);
            R3 = [ cos(theta), -sin(theta), 0; ...
                   sin(theta),  cos(theta), 0; ...
                   0,           0,          1];
            r_eci_m(:,k) = R3 * r_ecef_m(:,k);
        end
    
        if was_row_major
            r_eci_m = r_eci_m.';
        end
    end