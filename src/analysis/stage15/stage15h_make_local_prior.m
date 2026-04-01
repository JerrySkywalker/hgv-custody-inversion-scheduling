function prior = stage15h_make_local_prior(xi, eta, kappa2, baseline_km)
% Stage15-H2:
% 使用 H1 推荐模型 B，将 (lambda_min_geom, baseline_km) 映射到 cpt3 M_G 数轴，
% 再基于第三章阈值生成连续 prior。

if nargin < 4
    error('stage15h_make_local_prior requires baseline_km as the 4th input.');
end

calib = stage15h_get_geometry_calibration();

map_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_mapping', 'stage15h1_mapping_fit.mat');
assert(exist(map_mat, 'file') == 2, 'Missing H1 mapping fit mat: %s', map_mat);

Smap = load(map_mat);
assert(isfield(Smap, 'recommended_model'), 'Mapping mat missing recommended_model.');
assert(strcmp(Smap.recommended_model, 'B'), 'H2 expects recommended_model = B.');
assert(isfield(Smap, 'models') && isfield(Smap.models, 'B'), 'Mapping mat missing model B.');

modelB = Smap.models.B;

lambda_geom = kappa2.lambda_min_geom;
MG_hat = stage15h_map_geom_to_cpt3MG_modelB(lambda_geom, baseline_km, modelB);

prior = struct();
prior.lambda_geom = lambda_geom;
prior.baseline_km = baseline_km;
prior.M_G_center = MG_hat;

if MG_hat <= calib.M_G_thr_12
    prior.region_id = "low_M_G";
elseif MG_hat <= calib.M_G_thr_23
    prior.region_id = "mid_M_G";
else
    prior.region_id = "high_M_G";
end

% -----------------------------
% 连续 fragility
% -----------------------------
if MG_hat <= calib.M_G_thr_12
    alpha = max(0, min(1, MG_hat / max(calib.M_G_thr_12, eps)));
    prior.fragility_score = 1.0 - 0.4 * alpha;
elseif MG_hat <= calib.M_G_thr_23
    alpha = (MG_hat - calib.M_G_thr_12) / max(calib.M_G_thr_23 - calib.M_G_thr_12, eps);
    prior.fragility_score = 0.6 - 0.4 * alpha;
else
    alpha = 1 - exp(-(MG_hat - calib.M_G_thr_23) / 50.0);
    prior.fragility_score = max(0.05, 0.2 - 0.15 * alpha);
end

% -----------------------------
% 连续 R_geo 估计
% -----------------------------
Rmin = calib.R_geo_trusted_min_km;
Rmed = calib.R_geo_trusted_median_km;
Rmax = calib.R_geo_trusted_max_km;

if MG_hat <= calib.M_G_thr_12
    alpha = max(0, min(1, MG_hat / max(calib.M_G_thr_12, eps)));
    prior.R_geo_est = 0.5 * Rmin + 0.5 * alpha * Rmin;
elseif MG_hat <= calib.M_G_thr_23
    alpha = (MG_hat - calib.M_G_thr_12) / max(calib.M_G_thr_23 - calib.M_G_thr_12, eps);
    prior.R_geo_est = Rmin + alpha * (Rmax - Rmin);
else
    alpha = 1 - exp(-(MG_hat - calib.M_G_thr_23) / 50.0);
    prior.R_geo_est = Rmax - 0.4 * alpha * (Rmax - Rmed);
end

% -----------------------------
% 连续 box 尺度估计
% -----------------------------
Bnom_min = calib.Bxy_nominal_range_km(1);
Bnom_max = calib.Bxy_nominal_range_km(2);
Bcon_min = calib.Bxy_conservative_range_km(1);
Bcon_max = calib.Bxy_conservative_range_km(2);

if MG_hat <= calib.M_G_thr_12
    alpha = max(0, min(1, MG_hat / max(calib.M_G_thr_12, eps)));
    prior.Bxy_nominal_est = Bcon_min + alpha * (Bnom_min - Bcon_min);
    prior.Bxy_conservative_est = Bcon_min + 0.5 * alpha * (Bcon_max - Bcon_min);
elseif MG_hat <= calib.M_G_thr_23
    alpha = (MG_hat - calib.M_G_thr_12) / max(calib.M_G_thr_23 - calib.M_G_thr_12, eps);
    prior.Bxy_nominal_est = Bnom_min + alpha * (Bnom_max - Bnom_min);
    prior.Bxy_conservative_est = Bcon_min + alpha * (Bcon_max - Bcon_min);
else
    alpha = 1 - exp(-(MG_hat - calib.M_G_thr_23) / 50.0);
    prior.Bxy_nominal_est = Bnom_max - 0.3 * alpha * (Bnom_max - Bnom_min);
    prior.Bxy_conservative_est = Bcon_max - 0.3 * alpha * (Bcon_max - Bcon_min);
end

prior.step_xy_nominal_est = calib.step_xy_nominal_km;
prior.step_xy_conservative_est = calib.step_xy_conservative_km;

% 透传局部结构信息
prior.crossing_angle_deg = kappa2.crossing_angle_deg;
prior.lambda_min_geom = kappa2.lambda_min_geom;
prior.rho1_norm = kappa2.rho1_norm;
prior.rho2_norm = kappa2.rho2_norm;

if isfield(xi, 'r_norm_xy'); prior.r_norm_xy = xi.r_norm_xy; end
if isfield(xi, 'z_norm'); prior.z_norm = xi.z_norm; end
if isfield(eta, 'radial_rate_norm'); prior.radial_rate_norm = eta.radial_rate_norm; end
if isfield(eta, 'vertical_rate_norm'); prior.vertical_rate_norm = eta.vertical_rate_norm; end
end
