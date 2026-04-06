function case_i = build_manual_case_from_recipe_ch5b(recipe, cfg)
%BUILD_MANUAL_CASE_FROM_RECIPE_CH5B Build a synthetic case compatible with Stage02 kernel.

if nargin < 2 || isempty(cfg)
    cfg = default_ch5b_params();
end

Re_m = cfg.stage02.Re_m;
lat0_rad = deg2rad(cfg.geo.lat0_deg);
lon0_rad = deg2rad(cfg.geo.lon0_deg);

x_m = recipe.x0_km * 1000.0;
y_m = recipe.y0_km * 1000.0;

dphi = y_m / Re_m;
dlambda = x_m / (Re_m * cos(lat0_rad));

lat_deg = rad2deg(lat0_rad + dphi);
lon_deg = rad2deg(lon0_rad + dlambda);
h_m = recipe.h0_m;

entry_point_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, cfg).';
if size(entry_point_ecef_m,1) ~= 1
    entry_point_ecef_m = entry_point_ecef_m(:).';
end

entry_point_enu_m = ecef_to_local_enu( ...
    entry_point_ecef_m, ...
    cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m, cfg);

if size(entry_point_enu_m,1) ~= 1
    entry_point_enu_m = entry_point_enu_m(:).';
end

case_i = struct();
case_i.case_id = recipe.case_id;
case_i.family = recipe.family;
case_i.subfamily = recipe.subfamily;
case_i.heading_deg = recipe.heading_deg;
case_i.heading_offset_deg = recipe.heading_offset_deg;
case_i.entry_theta_deg = NaN;
case_i.entry_point_ecef_m = entry_point_ecef_m;
case_i.entry_point_enu_km = entry_point_enu_m / 1000.0;

case_i.recipe = recipe;
case_i.meta = struct();
case_i.meta.lat_deg = lat_deg;
case_i.meta.lon_deg = lon_deg;
case_i.meta.h_m = h_m;

end
