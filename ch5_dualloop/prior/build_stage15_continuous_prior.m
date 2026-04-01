function prior = build_stage15_continuous_prior(lambda_geom, baseline_km, crossing_angle_deg)
%BUILD_STAGE15_CONTINUOUS_PRIOR
% Map stage15-scale geometry descriptors into a continuous prior bundle.
%
% Current design:
%   1) map (lambda_geom, baseline_km, crossing_angle_deg) -> M_G_center (cpt3 scale)
%   2) assign a soft region label for reporting only
%   3) build a NON-SATURATED continuous fragility score
%
% Important:
%   region_id is now descriptive only.
%   fragility_score is continuous and keeps dynamic range inside high_M_G.

arguments
    lambda_geom (1,1) double
    baseline_km (1,1) double
    crossing_angle_deg (1,1) double
end

thr = get_stage15_mg_thresholds();

MG_center = stage15_map_to_mg_cpt3(lambda_geom, baseline_km, crossing_angle_deg);

if MG_center < thr.MG_thr_12
    region_id = "low_M_G";
elseif MG_center < thr.MG_thr_23
    region_id = "mid_M_G";
else
    region_id = "high_M_G";
end

% ------------------------------------------------
% Continuous fragility without hard saturation
%
% J_f = max(eps0, (M_ref / M_G)^alpha )
%
% Recommended initial setting:
%   eps0  = 0.05
%   M_ref = 120
%   alpha = 0.5
% ------------------------------------------------
eps0  = 0.05;
M_ref = thr.MG_thr_12;
alpha = 0.5;

MG_safe = max(MG_center, 1e-6);
fragility_score = max(eps0, (M_ref / MG_safe)^alpha);

% Keep old reference outputs for downstream compatibility.
R_geo_est = stage15_estimate_Rgeo_from_mg(MG_center);
Bxy_nominal_est = stage15_estimate_Bxy_nominal_from_mg(MG_center);
Bxy_conservative_est = stage15_estimate_Bxy_conservative_from_mg(MG_center);

prior = struct();
prior.lambda_geom = lambda_geom;
prior.baseline_km = baseline_km;
prior.crossing_angle_deg = crossing_angle_deg;

prior.M_G_center = MG_center;
prior.region_id = region_id;
prior.fragility_score = fragility_score;

prior.R_geo_est = R_geo_est;
prior.Bxy_nominal_est = Bxy_nominal_est;
prior.Bxy_conservative_est = Bxy_conservative_est;

prior.meta = struct();
prior.meta.eps0 = eps0;
prior.meta.M_ref = M_ref;
prior.meta.alpha = alpha;
end
