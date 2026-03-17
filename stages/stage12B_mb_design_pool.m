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

hi_design_table = local_build_hi_design_table(theta, slice_cfg);
pt_design_table = local_build_pt_design_table(theta, slice_cfg);
design_pool_table = unique_design_rows(vertcat(hi_design_table, pt_design_table));

joint_eval = evaluate_design_pool_with_stage09(cfg, design_pool_table, 'joint', local_eval_overrides(slice_cfg));
nominal_eval = evaluate_design_pool_with_stage09(cfg, design_pool_table, 'nominal', local_eval_overrides(slice_cfg));
heading_eval = evaluate_design_pool_with_stage09(cfg, design_pool_table, 'heading', local_eval_overrides(slice_cfg));
critical_eval = evaluate_design_pool_with_stage09(cfg, design_pool_table, 'critical', local_eval_overrides(slice_cfg));

pool = struct();
pool.cfg = cfg;
pool.meta = meta;
pool.baseline_theta = theta;
pool.slice_anchor_hi = struct('P', theta.P, 'T', theta.T, 'F', theta.F);
pool.slice_anchor_pt = struct('h_km', theta.h_km, 'i_deg', theta.i_deg, 'F', theta.F);
pool.hi_design_table = hi_design_table;
pool.pt_design_table = pt_design_table;
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
    'slice_anchor_hi', pool.slice_anchor_hi, ...
    'slice_anchor_pt', pool.slice_anchor_pt, ...
    'casebank_size_joint', joint_eval.summary.casebank_size, ...
    'casebank_size_nominal', nominal_eval.summary.casebank_size, ...
    'casebank_size_heading', heading_eval.summary.casebank_size, ...
    'casebank_size_critical', critical_eval.summary.casebank_size);
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

function overrides = local_eval_overrides(slice_cfg)
overrides = struct('heading_subset_max', slice_cfg.heading_subset_max);
end
