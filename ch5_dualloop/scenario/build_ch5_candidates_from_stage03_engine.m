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

% Build a lightweight traj_case wrapper compatible with Stage03 visibility interface.
traj_case = struct();
traj_case.case_id = 'ch5_dynamic_case';
traj_case.traj = struct();
traj_case.traj.t_s = truth.t(:);
traj_case.traj.r_eci_km = truth.r_eci_km;

cfg_local = cfg;

% Map chapter-5 sensor visibility settings into stage03 fields when available.
if ~isfield(cfg_local, 'stage03')
    cfg_local.stage03 = struct();
end
cfg_local.stage03.max_range_km = cfg.sensor.max_range_km;
cfg_local.stage03.off_nadir_max_deg = 90;
cfg_local.stage03.min_elevation_deg = -90;
cfg_local.stage03.enable_earth_occlusion = true;

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
