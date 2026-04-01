function prior = build_stage15_continuous_prior(lambda_geom, baseline_km, crossing_angle_deg)
% 构造 Stage15 连续几何先验
%
% 输入:
%   lambda_geom
%   baseline_km
%   crossing_angle_deg
%
% 输出:
%   prior.M_G_center
%   prior.region_id
%   prior.fragility_score
%   prior.R_geo_est
%   prior.Bxy_nominal_est
%   prior.Bxy_conservative_est

assert(exist('stage15h_map_geom_to_cpt3MG_modelB', 'file') == 2, ...
    'Missing stage15h_map_geom_to_cpt3MG_modelB on path.');
assert(exist('stage15h_get_geometry_calibration', 'file') == 2, ...
    'Missing stage15h_get_geometry_calibration on path.');

map_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_mapping', 'stage15h1_mapping_fit.mat');
assert(exist(map_mat, 'file') == 2, 'Missing H1 mapping fit mat: %s', map_mat);

Smap = load(map_mat);
assert(strcmp(Smap.recommended_model, 'B'), 'Expected recommended model B.');

modelB = Smap.models.B;
calib = stage15h_get_geometry_calibration();

MG_hat = stage15h_map_geom_to_cpt3MG_modelB(lambda_geom, baseline_km, modelB);

prior = struct();
prior.lambda_geom = lambda_geom;
prior.baseline_km = baseline_km;
prior.crossing_angle_deg = crossing_angle_deg;
prior.M_G_center = MG_hat;

if MG_hat <= calib.M_G_thr_12
    prior.region_id = "low_M_G";
elseif MG_hat <= calib.M_G_thr_23
    prior.region_id = "mid_M_G";
else
    prior.region_id = "high_M_G";
end

Rmin = calib.R_geo_trusted_min_km;
Rmed = calib.R_geo_trusted_median_km;
Rmax = calib.R_geo_trusted_max_km;

Bnom_min = calib.Bxy_nominal_range_km(1);
Bnom_max = calib.Bxy_nominal_range_km(2);
Bcon_min = calib.Bxy_conservative_range_km(1);
Bcon_max = calib.Bxy_conservative_range_km(2);

if MG_hat <= calib.M_G_thr_12
    alpha = max(0, min(1, MG_hat / max(calib.M_G_thr_12, eps)));
    prior.fragility_score = 1.0 - 0.4 * alpha;
    prior.R_geo_est = 0.5 * Rmin + 0.5 * alpha * Rmin;
    prior.Bxy_nominal_est = Bcon_min + alpha * (Bnom_min - Bcon_min);
    prior.Bxy_conservative_est = Bcon_min + 0.5 * alpha * (Bcon_max - Bcon_min);
elseif MG_hat <= calib.M_G_thr_23
    alpha = (MG_hat - calib.M_G_thr_12) / max(calib.M_G_thr_23 - calib.M_G_thr_12, eps);
    prior.fragility_score = 0.6 - 0.4 * alpha;
    prior.R_geo_est = Rmin + alpha * (Rmax - Rmin);
    prior.Bxy_nominal_est = Bnom_min + alpha * (Bnom_max - Bnom_min);
    prior.Bxy_conservative_est = Bcon_min + alpha * (Bcon_max - Bcon_min);
else
    alpha = 1 - exp(-(MG_hat - calib.M_G_thr_23) / 50.0);
    prior.fragility_score = max(0.05, 0.2 - 0.15 * alpha);
    prior.R_geo_est = Rmax - 0.4 * alpha * (Rmax - Rmed);
    prior.Bxy_nominal_est = Bnom_max - 0.3 * alpha * (Bnom_max - Bnom_min);
    prior.Bxy_conservative_est = Bcon_max - 0.3 * alpha * (Bcon_max - Bcon_min);
end

prior.step_xy_nominal_est = calib.step_xy_nominal_km;
prior.step_xy_conservative_est = calib.step_xy_conservative_km;
end
