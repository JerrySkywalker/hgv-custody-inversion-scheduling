function prior = stage15h_make_local_prior(xi, eta, kappa2)
% Stage15-H:
% 将局部几何核 (xi, eta, kappa2) 转为连续先验量。
%
% 输入:
%   xi, eta, kappa2  来自 Stage15 sample
%
% 输出:
%   prior.M_G_center
%   prior.region_id
%   prior.fragility_score
%   prior.R_geo_est
%   prior.Bxy_nominal_est
%   prior.Bxy_conservative_est
%   prior.step_xy_nominal_est
%   prior.step_xy_conservative_est

calib = stage15h_get_geometry_calibration();

MG = kappa2.lambda_min_geom;

prior = struct();
prior.M_G_center = MG;

if MG <= calib.M_G_thr_12
    prior.region_id = "low_M_G";
elseif MG <= calib.M_G_thr_23
    prior.region_id = "mid_M_G";
else
    prior.region_id = "high_M_G";
end

% 脆弱度：0~1，值越大越脆弱
if MG <= calib.M_G_thr_12
    prior.fragility_score = 1.0;
elseif MG <= calib.M_G_thr_23
    prior.fragility_score = 1.0 - (MG - calib.M_G_thr_12) / max(calib.M_G_thr_23 - calib.M_G_thr_12, eps);
else
    % 高 M_G 区保留一个非零脆弱度尾巴，避免过硬切换
    prior.fragility_score = max(0.05, 0.2 * exp(-(MG - calib.M_G_thr_23) / 50.0));
end

% 先用 region 级别 piecewise 值估计 R_geo
switch char(prior.region_id)
    case 'low_M_G'
        % 低 M_G 区当前 R_geo 受扫描域截断影响，不可信；仅给最小保护值
        prior.R_geo_est = calib.R_geo_trusted_min_km;
        prior.Bxy_nominal_est = calib.Bxy_conservative_range_km(1);
        prior.Bxy_conservative_est = calib.Bxy_conservative_range_km(1);
    case 'mid_M_G'
        prior.R_geo_est = calib.R_geo_trusted_max_km;
        prior.Bxy_nominal_est = calib.Bxy_nominal_range_km(2);
        prior.Bxy_conservative_est = calib.Bxy_conservative_range_km(2);
    otherwise % high_M_G
        prior.R_geo_est = calib.R_geo_trusted_median_km;
        prior.Bxy_nominal_est = mean(calib.Bxy_nominal_range_km);
        prior.Bxy_conservative_est = mean(calib.Bxy_conservative_range_km);
end

prior.step_xy_nominal_est = calib.step_xy_nominal_km;
prior.step_xy_conservative_est = calib.step_xy_conservative_km;

% 一些透传信息，便于 Phase08 / J 阶段直接消费
prior.crossing_angle_deg = kappa2.crossing_angle_deg;
prior.lambda_min_geom = kappa2.lambda_min_geom;
prior.rho1_norm = kappa2.rho1_norm;
prior.rho2_norm = kappa2.rho2_norm;

if isfield(xi, 'r_norm_xy'); prior.r_norm_xy = xi.r_norm_xy; end
if isfield(xi, 'z_norm'); prior.z_norm = xi.z_norm; end
if isfield(eta, 'radial_rate_norm'); prior.radial_rate_norm = eta.radial_rate_norm; end
if isfield(eta, 'vertical_rate_norm'); prior.vertical_rate_norm = eta.vertical_rate_norm; end
end
