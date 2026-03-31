function truth = build_ch5_truth_from_stage02_engine(profile, cfg)
%BUILD_CH5_TRUTH_FROM_STAGE02_ENGINE  Build chapter 5 truth using Stage02 engine.
%
% This function does not modify any chapter 4 code.
% It wraps existing Stage02 propagation capability if available.

if nargin < 1 || isempty(profile)
    profile = build_ch5_target_profile(cfg);
end
if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

requiredFns = { ...
    'build_hgv_cfg_from_case_stage02', ...
    'propagate_hgv_case_stage02'};

for i = 1:numel(requiredFns)
    if exist(requiredFns{i}, 'file') ~= 2
        error('Required Stage02 function not found on path: %s', requiredFns{i});
    end
end

% Construct a lightweight pseudo-case compatible with Stage02 builders.
case_i = struct();
case_i.id = 'ch5_dynamic_case';
case_i.kind = 'ch5_dynamic';
case_i.name = 'Chapter5 Dynamic Case';
case_i.lat0_deg = profile.lat0_deg;
case_i.lon0_deg = profile.lon0_deg;
case_i.h0_m = profile.h0_m;
case_i.speed0_mps = profile.speed0_mps;
case_i.gamma0_deg = profile.gamma0_deg;
case_i.heading0_deg = profile.heading0_deg;

% Try to let Stage02 builder fill the detailed propagation config.
hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg);

% Phase-2.5A explicitly overwrites a few fields from chapter-5 profile when present.
overrideFields = {'h0_m','speed0_mps','gamma0_deg','heading0_deg'};
for i = 1:numel(overrideFields)
    f = overrideFields{i};
    if isfield(profile, f)
        hgv_cfg.(f) = profile.(f);
    end
end

traj = propagate_hgv_case_stage02(case_i, cfg, hgv_cfg);

truth = struct();
truth.source = 'stage02_engine';
truth.profile = profile;
truth.t = traj.t_s(:);

if isfield(traj, 'r_eci_km');  truth.r_eci_km  = traj.r_eci_km;  end
if isfield(traj, 'r_ecef_km'); truth.r_ecef_km = traj.r_ecef_km; end
if isfield(traj, 'r_enu_km');  truth.r_enu_km  = traj.r_enu_km;  end
if isfield(traj, 'lat_deg');   truth.lat_deg   = traj.lat_deg(:); end
if isfield(traj, 'lon_deg');   truth.lon_deg   = traj.lon_deg(:); end

if isfield(traj, 'h_km')
    truth.h_km = traj.h_km(:);
elseif isfield(traj, 'h_m')
    truth.h_km = traj.h_m(:) / 1000.0;
else
    truth.h_km = nan(size(truth.t));
end

if isfield(traj, 'X')
    truth.X = traj.X;
    if size(traj.X, 2) >= 6
        truth.x = traj.X(:, 1);
        truth.y = traj.X(:, 2);
        truth.z = traj.X(:, 3);
        truth.vx = traj.X(:, 4);
        truth.vy = traj.X(:, 5);
        truth.vz = traj.X(:, 6);
    end
end

truth.meta = struct();
truth.meta.case_id = case_i.id;
truth.meta.generated_by = mfilename;
truth.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end
