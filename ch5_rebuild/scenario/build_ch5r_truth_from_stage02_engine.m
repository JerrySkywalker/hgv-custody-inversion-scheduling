function truth = build_ch5r_truth_from_stage02_engine(cfg)
%BUILD_CH5R_TRUTH_FROM_STAGE02_ENGINE
% Load a real nominal HGV trajectory case from the latest Stage02 cache.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end

d = find_stage_cache_files(cfg, 'stage02_hgv_nominal_*.mat');
assert(~isempty(d), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

[~, idx] = max([d.datenum]);
stage02_file = fullfile(d(idx).folder, d(idx).name);

S = load(stage02_file);
assert(isfield(S, 'out') && isfield(S.out, 'trajbank'), ...
    'Invalid Stage02 cache: missing out.trajbank');

trajbank = S.out.trajbank;
case_id = string(cfg.ch5r.target_case.case_id);

all_cases = [trajbank.nominal; trajbank.heading; trajbank.critical];
all_case_ids = string(cellfun(@(c) c.case_id, {all_cases.case}, 'UniformOutput', false));

hit_idx = find(strcmp(all_case_ids, case_id), 1, 'first');
assert(~isempty(hit_idx), 'Stage02 case %s not found.', case_id);

traj_case = all_cases(hit_idx);

truth = struct();
truth.source = 'stage02_real_cache';
truth.stage02_file = stage02_file;
truth.case_id = traj_case.case.case_id;
truth.family = traj_case.case.family;
truth.subfamily = traj_case.case.subfamily;
truth.traj_case = traj_case;
truth.t_s = traj_case.traj.t_s(:);
truth.r_eci_km = traj_case.traj.r_eci_km;

if isfield(traj_case.traj, 'r_ecef_km')
    truth.r_ecef_km = traj_case.traj.r_ecef_km;
end
if isfield(traj_case.traj, 'r_enu_km')
    truth.r_enu_km = traj_case.traj.r_enu_km;
end
if isfield(traj_case.traj, 'lat_deg')
    truth.lat_deg = traj_case.traj.lat_deg(:);
end
if isfield(traj_case.traj, 'lon_deg')
    truth.lon_deg = traj_case.traj.lon_deg(:);
end
if isfield(traj_case.traj, 'h_km')
    truth.h_km = traj_case.traj.h_km(:);
end
if isfield(traj_case.traj, 'X')
    truth.X = traj_case.traj.X;
end

truth.meta = struct();
truth.meta.note = 'Real HGV trajectory loaded from latest Stage02 cache.';
end
