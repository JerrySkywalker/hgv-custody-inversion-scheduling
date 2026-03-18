function pool = stage12B_mb_design_pool(cfg, overrides)
%STAGE12B_MB_DESIGN_POOL Build the unified Milestone B design pool and evaluate its truth tables.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
if isstruct(overrides)
    meta = milestone_common_merge_structs(meta, overrides);
end

theta = cfg.milestones.baseline_theta;
if isfield(meta, 'theta') && isstruct(meta.theta)
    theta = milestone_common_merge_structs(theta, meta.theta);
end
slice_cfg = meta.slice_settings;

t_hi = tic;
hi_design_table = local_build_hi_design_table(theta, slice_cfg);
t_hi_s = toc(t_hi);
fprintf('[MB] hi slice design table built: %d rows in %.2fs.\n', height(hi_design_table), t_hi_s);
t_pt = tic;
pt_design_table = local_build_pt_design_table(theta, slice_cfg);
t_pt_s = toc(t_pt);
fprintf('[MB] pt slice design table built: %d rows in %.2fs.\n', height(pt_design_table), t_pt_s);
t_local = tic;
local_block_table = local_build_minimum_neighborhood_table(theta, slice_cfg, meta);
t_local_s = toc(t_local);
fprintf('[MB] local neighborhood block built: %d rows in %.2fs.\n', height(local_block_table), t_local_s);
t_merge = tic;
design_pool_table = unique_design_rows(vertcat(hi_design_table, pt_design_table, local_block_table));
t_merge_s = toc(t_merge);
fprintf('[MB] unified design pool ready: %d unique designs in %.2fs.\n', height(design_pool_table), t_merge_s);

t_joint = tic;
joint_eval = evaluate_design_pool_with_stage09(cfg, design_pool_table, 'joint', local_eval_overrides(cfg, meta, slice_cfg));
t_joint_s = toc(t_joint);
fprintf('[MB] joint truth evaluation finished in %.2fs.\n', t_joint_s);
t_nominal = tic;
nominal_eval = derive_family_eval_from_joint(joint_eval, 'nominal', joint_eval.cfg);
t_nominal_s = toc(t_nominal);
t_heading = tic;
heading_eval = derive_family_eval_from_joint(joint_eval, 'heading', joint_eval.cfg);
t_heading_s = toc(t_heading);
t_critical = tic;
critical_eval = derive_family_eval_from_joint(joint_eval, 'critical', joint_eval.cfg);
t_critical_s = toc(t_critical);
fprintf('[MB] derived family subsets in %.2fs / %.2fs / %.2fs (nominal / heading / critical).\n', ...
    t_nominal_s, t_heading_s, t_critical_s);

pool = struct();
pool.cfg = cfg;
pool.meta = meta;
pool.baseline_theta = theta;
pool.slice_anchor_hi = struct('P', theta.P, 'T', theta.T, 'F', theta.F);
pool.slice_anchor_pt = struct('h_km', theta.h_km, 'i_deg', theta.i_deg, 'F', theta.F);
pool.hi_design_table = hi_design_table;
pool.pt_design_table = pt_design_table;
pool.local_block_table = local_block_table;
pool.design_pool_table = design_pool_table;
pool.full_theta_table_joint = joint_eval.full_theta_table;
pool.feasible_theta_table_joint = joint_eval.feasible_theta_table;
pool.full_theta_table_nominal = nominal_eval.full_theta_table;
pool.feasible_theta_table_nominal = nominal_eval.feasible_theta_table;
pool.full_theta_table_heading = heading_eval.full_theta_table;
pool.feasible_theta_table_heading = heading_eval.feasible_theta_table;
pool.full_theta_table_critical = critical_eval.full_theta_table;
pool.feasible_theta_table_critical = critical_eval.feasible_theta_table;
pool.family_eval = struct('joint', joint_eval, 'nominal', nominal_eval, 'heading', heading_eval, 'critical', critical_eval);
pool.summary = struct( ...
    'num_unique_grid_points', height(design_pool_table), ...
    'num_unique_feasible_points', height(joint_eval.feasible_theta_table), ...
    'fast_mode', isfield(meta, 'fast_mode') && logical(meta.fast_mode), ...
    'timing', struct( ...
        'build_hi_design_table_s', t_hi_s, ...
        'build_pt_design_table_s', t_pt_s, ...
        'build_local_block_table_s', t_local_s, ...
        'merge_unique_design_pool_s', t_merge_s, ...
        'joint_truth_evaluation_s', t_joint_s, ...
        'derive_nominal_s', t_nominal_s, ...
        'derive_heading_s', t_heading_s, ...
        'derive_critical_s', t_critical_s), ...
    'slice_anchor_hi', pool.slice_anchor_hi, ...
    'slice_anchor_pt', pool.slice_anchor_pt, ...
    'casebank_size_joint', joint_eval.summary.casebank_size, ...
    'casebank_size_nominal', nominal_eval.summary.casebank_size, ...
    'casebank_size_heading', heading_eval.summary.casebank_size, ...
    'casebank_size_critical', critical_eval.summary.casebank_size, ...
    'joint_eval_timing', joint_eval.timing);
end

function T = local_build_hi_design_table(theta, slice_cfg)
[H, I] = ndgrid(slice_cfg.h_km(:), slice_cfg.i_deg(:));
n = numel(H);
T = table(H(:), I(:), repmat(theta.P, n, 1), repmat(theta.T, n, 1), repmat(theta.F, n, 1), ...
    repmat(theta.P * theta.T, n, 1), repmat("hi", n, 1), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
T = sortrows(T, {'Ns', 'h_km', 'i_deg'}, {'ascend', 'ascend', 'ascend'});
end

function T = local_build_pt_design_table(theta, slice_cfg)
[P, TT] = ndgrid(slice_cfg.P(:), slice_cfg.T(:));
n = numel(P);
T = table(repmat(theta.h_km, n, 1), repmat(theta.i_deg, n, 1), P(:), TT(:), repmat(theta.F, n, 1), ...
    P(:) .* TT(:), repmat("pt", n, 1), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
T = sortrows(T, {'Ns', 'P', 'T'}, {'ascend', 'ascend', 'ascend'});
end

function overrides = local_eval_overrides(cfg, meta, slice_cfg)
overrides = struct();
overrides.heading_subset_max = slice_cfg.heading_subset_max;
overrides.save_case_window_bank = false;
if isfield(meta, 'fast_mode')
    overrides.fast_mode = logical(meta.fast_mode);
    if overrides.fast_mode && isfield(meta, 'fast_heading_subset_max') && ~isempty(meta.fast_heading_subset_max)
        overrides.heading_subset_max = meta.fast_heading_subset_max;
    end
end
if isfield(cfg.stage09, 'enable_checkpoint')
    overrides.enable_checkpoint = cfg.stage09.enable_checkpoint;
end
if isfield(cfg.stage09, 'checkpoint_every_n')
    overrides.checkpoint_every_n = cfg.stage09.checkpoint_every_n;
end
if isfield(cfg.stage09, 'checkpoint_dir')
    overrides.checkpoint_dir = cfg.stage09.checkpoint_dir;
end
if isfield(cfg.stage09, 'resume_from_checkpoint')
    overrides.resume_from_checkpoint = cfg.stage09.resume_from_checkpoint;
end
end

function T = local_build_minimum_neighborhood_table(theta, ~, meta)
h_grid = [800, 900, 1000];
i_grid = [50, 60, 70];
P_grid = [6, 8, 10];
T_grid = [6, 8, 10];
if isfield(meta, 'fast_mode') && logical(meta.fast_mode) && isfield(meta, 'fast_local_block') && logical(meta.fast_local_block)
    h_grid = meta.fast_local_block_h_km;
    i_grid = meta.fast_local_block_i_deg;
    P_grid = meta.fast_local_block_P;
    T_grid = meta.fast_local_block_T;
end
[H, I, P, TT] = ndgrid(h_grid, i_grid, P_grid, T_grid);
n = numel(H);
T = table(H(:), I(:), P(:), TT(:), repmat(theta.F, n, 1), P(:) .* TT(:), repmat("local_block", n, 1), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
T = sortrows(T, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end
