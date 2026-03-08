function c = wgs84_constants()
    %WGS84_CONSTANTS Return WGS84 ellipsoid constants.
    
        c = struct();
        c.a_m = 6378137.0;                 % semi-major axis [m]
        c.f   = 1 / 298.257223563;         % flattening
        c.b_m = c.a_m * (1 - c.f);         % semi-minor axis [m]
        c.e2  = 2*c.f - c.f^2;             % first eccentricity squared
    end