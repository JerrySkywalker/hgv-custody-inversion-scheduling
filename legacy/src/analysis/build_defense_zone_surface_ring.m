function zone = build_defense_zone_surface_ring(cfg)
%BUILD_DEFENSE_ZONE_SURFACE_RING Build defense-zone footprint in ECEF.

cfg = shared_scenario_common_defaults(cfg);

lat_deg = cfg.shared_scenarios.zone.center_lat_deg;
lon_deg = cfg.shared_scenarios.zone.center_lon_deg;
radius_m = cfg.shared_scenarios.zone.radius_km * 1e3;
earth_radius_m = cfg.shared_scenarios.earth_radius_m;

lat_rad = deg2rad(lat_deg);
lon_rad = deg2rad(lon_deg);

up_hat = [cos(lat_rad) * cos(lon_rad), cos(lat_rad) * sin(lon_rad), sin(lat_rad)];
east_hat = [-sin(lon_rad), cos(lon_rad), 0];
north_hat = cross(up_hat, east_hat);
north_hat = north_hat / norm(north_hat);

alpha = radius_m / earth_radius_m;
phi = linspace(0, 2 * pi, 241);

center_ecef_m = earth_radius_m * up_hat;
ring_unit = cos(alpha) * up_hat + sin(alpha) * (cos(phi(:)) .* east_hat + sin(phi(:)) .* north_hat);
ring_ecef_m = earth_radius_m * ring_unit;

zone = struct();
zone.center_lat_deg = lat_deg;
zone.center_lon_deg = lon_deg;
zone.radius_km = cfg.shared_scenarios.zone.radius_km;
zone.center_ecef_m = center_ecef_m(:);
zone.center_ecef_km = center_ecef_m(:).' / 1000;
zone.ring_ecef_m = ring_ecef_m;
zone.ring_ecef_km = ring_ecef_m / 1000;
zone.east_hat = east_hat;
zone.north_hat = north_hat;
zone.up_hat = up_hat;
end
