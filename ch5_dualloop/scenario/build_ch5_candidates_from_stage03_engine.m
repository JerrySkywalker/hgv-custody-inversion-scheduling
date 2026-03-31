function candidates = build_ch5_candidates_from_stage03_engine(truth, satbank, cfg)
%BUILD_CH5_CANDIDATES_FROM_STAGE03_ENGINE  Build chapter 5 candidate sets using Stage03 visibility engine.

if nargin < 1 || isempty(truth)
    error('truth is required.');
end
if nargin < 2 || isempty(satbank)
    error('satbank is required.');
end
if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

requiredFns = { ...
    'compute_visibility_matrix_stage03'};

for i = 1:numel(requiredFns)
    if exist(requiredFns{i}, 'file') ~= 2
        error('Required Stage03 visibility function not found on path: %s', requiredFns{i});
    end
end

% Build a traj_case wrapper compatible with Stage03 visibility interface.
traj_case = struct();
traj_case.case = struct();
traj_case.case.case_id = 'ch5_dynamic_case';
traj_case.case.family = 'nominal';
traj_case.case.subfamily = 'chapter5_dynamic';
traj_case.case.name = 'Chapter5 Dynamic Case';

traj_case.traj = struct();
traj_case.traj.t_s = truth.t(:);
traj_case.traj.r_eci_km = truth.r_eci_km;

% Optional fields, added only when available
if isfield(truth, 'r_ecef_km')
    traj_case.traj.r_ecef_km = truth.r_ecef_km;
end
if isfield(truth, 'r_enu_km')
    traj_case.traj.r_enu_km = truth.r_enu_km;
end
if isfield(truth, 'lat_deg')
    traj_case.traj.lat_deg = truth.lat_deg(:);
end
if isfield(truth, 'lon_deg')
    traj_case.traj.lon_deg = truth.lon_deg(:);
end
if isfield(truth, 'h_km')
    traj_case.traj.h_km = truth.h_km(:);
end
if isfield(truth, 'X')
    traj_case.traj.X = truth.X;
end

cfg_local = cfg;

if ~isfield(cfg_local, 'stage03')
    cfg_local.stage03 = struct();
end

% Map chapter-5 sensor settings into stage03 visibility settings
cfg_local.stage03.max_range_km = cfg.sensor.max_range_km;

if ~isfield(cfg_local.stage03, 'off_nadir_max_deg')
    cfg_local.stage03.off_nadir_max_deg = 90;
end
if ~isfield(cfg_local.stage03, 'min_elevation_deg')
    cfg_local.stage03.min_elevation_deg = -90;
end
if ~isfield(cfg_local.stage03, 'enable_earth_occlusion')
    cfg_local.stage03.enable_earth_occlusion = true;
end

vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_local);

visible_mask = vis_case.visible_mask;
Nt = size(visible_mask, 1);

sets = cell(Nt, 1);
count = zeros(Nt, 1);

for k = 1:Nt
    sets{k} = find(visible_mask(k, :));
    count(k) = numel(sets{k});
end

candidates = struct();
candidates.source = 'stage03_visibility';
candidates.sets = sets;
candidates.count = count;
candidates.visible_mask = visible_mask;
candidates.num_visible = vis_case.num_visible;
candidates.dual_coverage_mask = vis_case.dual_coverage_mask;
candidates.vis_case = vis_case;

candidates.min_count = min(count);
candidates.max_count = max(count);
candidates.mean_count = mean(count);

candidates.meta = struct();
candidates.meta.generated_by = mfilename;
candidates.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end
