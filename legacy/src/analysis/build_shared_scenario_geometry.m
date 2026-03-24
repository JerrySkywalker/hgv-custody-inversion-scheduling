function geom = build_shared_scenario_geometry(cfg)
%BUILD_SHARED_SCENARIO_GEOMETRY Build simplified geometry for shared illustrations.

cfg = shared_scenario_common_defaults(cfg);

lat_deg = cfg.shared_scenarios.zone_center_lat_deg;
lon_deg = cfg.shared_scenarios.zone_center_lon_deg;
zone_radius_km = cfg.shared_scenarios.zone_radius_km;

center_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, 0, cfg);
center_ecef_km = center_ecef_m(:).' / 1000;

lat_rad = deg2rad(lat_deg);
lon_rad = deg2rad(lon_deg);
east_hat = [-sin(lon_rad), cos(lon_rad), 0];
north_hat = [-sin(lat_rad) * cos(lon_rad), -sin(lat_rad) * sin(lon_rad), cos(lat_rad)];
up_hat = [cos(lat_rad) * cos(lon_rad), cos(lat_rad) * sin(lon_rad), sin(lat_rad)];

phi = linspace(0, 2 * pi, 240);
zone_ring_km = center_ecef_km + zone_radius_km * (cos(phi(:)) .* east_hat + sin(phi(:)) .* north_hat);

cfg_walker = cfg;
cfg_walker.stage03.h_km = cfg.shared_scenarios.baseline_theta.h_km;
cfg_walker.stage03.i_deg = cfg.shared_scenarios.baseline_theta.i_deg;
cfg_walker.stage03.P = cfg.shared_scenarios.baseline_theta.P;
cfg_walker.stage03.T = cfg.shared_scenarios.baseline_theta.T;
cfg_walker.stage03.F = cfg.shared_scenarios.baseline_theta.F;
walker = build_single_layer_walker_stage03(cfg_walker);
satbank = propagate_constellation_stage03(walker, [0, 1200]);

geom = struct();
geom.zone_center_lat_deg = lat_deg;
geom.zone_center_lon_deg = lon_deg;
geom.zone_radius_km = zone_radius_km;
geom.center_ecef_km = center_ecef_km;
geom.zone_ring_ecef_km = zone_ring_km;
geom.east_hat = east_hat;
geom.north_hat = north_hat;
geom.up_hat = up_hat;
geom.walker = walker;
geom.satbank = satbank;
geom.earth_radius_km = cfg.geo.a_m / 1000;
end
