function prior = build_stage15_continuous_prior(lambda_geom, baseline_km, crossing_angle_deg)
%BUILD_STAGE15_CONTINUOUS_PRIOR
% Self-contained continuous prior builder for Phase08 integration.
%
% Inputs:
%   lambda_geom
%   baseline_km
%   crossing_angle_deg
%
% Outputs:
%   prior.M_G_center
%   prior.region_id
%   prior.fragility_score
%   prior.R_geo_est
%   prior.Bxy_nominal_est
%   prior.Bxy_conservative_est

arguments
    lambda_geom (1,1) double
    baseline_km (1,1) double
    crossing_angle_deg (1,1) double
end

% ------------------------------------------------
% Chapter-3 aligned thresholds
% ------------------------------------------------
MG_thr_12 = 115.411378;
MG_thr_23 = 198.489832;

% ------------------------------------------------
% Cross-scale mapping from Stage15 geometry scale to cpt3 M_G scale
% Reuse the fitted H1 model B if available.
% ------------------------------------------------
assert(exist('stage15h_map_geom_to_cpt3MG_modelB', 'file') == 2, ...
    'Missing stage15h_map_geom_to_cpt3MG_modelB on path.');

map_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_mapping', 'stage15h1_mapping_fit.mat');
assert(exist(map_mat, 'file') == 2, 'Missing H1 mapping fit mat: %s', map_mat);

Smap = load(map_mat);
assert(isfield(Smap, 'models') && isfield(Smap.models, 'B'), 'Mapping mat missing model B.');

modelB = Smap.models.B;
MG_center = stage15h_map_geom_to_cpt3MG_modelB(lambda_geom, baseline_km, modelB);

% ------------------------------------------------
% Soft region label for reporting only
% ------------------------------------------------
if MG_center < MG_thr_12
    region_id = "low_M_G";
elseif MG_center < MG_thr_23
    region_id = "mid_M_G";
else
    region_id = "high_M_G";
end

% ------------------------------------------------
% Continuous fragility without saturation
%
% J_f = max(eps0, (M_ref / M_G)^alpha )
% ------------------------------------------------
eps0  = 0.05;
M_ref = MG_thr_12;
alpha = 0.5;

MG_safe = max(MG_center, 1e-6);
fragility_score = max(eps0, (M_ref / MG_safe)^alpha);

% ------------------------------------------------
% Smooth surrogate estimates for downstream compatibility
% These are not hard labels; they only provide soft reference scales.
% ------------------------------------------------
MG_clip = max(0.0, min(1.0, (MG_center - MG_thr_12) / max(MG_thr_23 - MG_thr_12, eps)));

R_geo_est = 120 + 180 * MG_clip;             % ~ [120, 300] km
Bxy_nominal_est = 60 + 120 * MG_clip;        % ~ [60, 180] km
Bxy_conservative_est = 45 + 90 * MG_clip;    % ~ [45, 135] km

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
prior.meta.MG_thr_12 = MG_thr_12;
prior.meta.MG_thr_23 = MG_thr_23;
prior.meta.eps0 = eps0;
prior.meta.M_ref = M_ref;
prior.meta.alpha = alpha;
end
