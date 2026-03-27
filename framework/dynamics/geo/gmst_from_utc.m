function gmst_rad = gmst_from_utc(utc_input)
    %GMST_FROM_UTC Compute Greenwich Mean Sidereal Time [rad].
    %
    % Lightweight implementation sufficient for current geodetic-anchor stage.
    
        jd = julian_date_from_utc(utc_input);
        T = (jd - 2451545.0) / 36525.0;
    
        gmst_deg = 280.46061837 ...
                 + 360.98564736629 * (jd - 2451545.0) ...
                 + 0.000387933 * T^2 ...
                 - (T^3) / 38710000.0;
    
        gmst_deg = mod(gmst_deg, 360.0);
        gmst_rad = deg2rad(gmst_deg);
    end
