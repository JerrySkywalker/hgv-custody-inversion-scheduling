function r_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, cfg)
    %GEODETIC_TO_ECEF Convert geodetic coordinates to ECEF position [m].
    %
    % Supports scalar or array-valued lat/lon/h inputs with matching size.

    lat = deg2rad(lat_deg);
    lon = deg2rad(lon_deg);

    a = cfg.geo.a_m;
    e2 = cfg.geo.e2;

    sin_lat = sin(lat);
    cos_lat = cos(lat);
    sin_lon = sin(lon);
    cos_lon = cos(lon);

    N = a ./ sqrt(1 - e2 .* sin_lat.^2);

    x = (N + h_m) .* cos_lat .* cos_lon;
    y = (N + h_m) .* cos_lat .* sin_lon;
    z = (N .* (1 - e2) + h_m) .* sin_lat;

    r_ecef_m = [x(:).'; y(:).'; z(:).'];

    if isscalar(x)
        r_ecef_m = r_ecef_m(:, 1);
    end
end

