function out = stage12A_truth_baseline_kernel(cfg, overrides)
%STAGE12A_TRUTH_BASELINE_KERNEL Build a controlled truth baseline result for Milestone A.

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_defaults(cfg);
cfg = stage09_prepare_cfg(cfg);

selection = milestone_common_case_selection(cfg, 'MA', overrides);
theta = local_resolve_theta(cfg, overrides);
Tw_s = local_resolve_Tw(cfg, overrides);
cfg.stage04.Tw_s = Tw_s;
cfg.stage09.Tw_source = 'manual';
cfg.stage09.Tw_manual_s = Tw_s;
cfg.stage09.run_tag = 'stage12A_truth_baseline_kernel';

trajs_in = local_build_selected_casebank(selection, cfg);
theta_row = local_build_theta_row(theta);
eval_ctx = build_stage09_eval_context(trajs_in, cfg, 1.0);
result = evaluate_single_layer_walker_stage09(theta_row, trajs_in, 1.0, cfg, eval_ctx);
case_row = result.case_table(1, :);
dominant_metric = classify_dominant_metric(result.DG_rob, result.DA_rob, result.DT_rob);
is_feasible_truth = (result.DG_rob >= 1) && (result.DA_rob >= 1) && (result.DT_rob >= 1);

summary_table = table( ...
    string(selection.case_id), string(selection.case_family), ...
    theta_row.h_km, theta_row.i_deg, theta_row.P, theta_row.T, theta_row.F, theta_row.Ns, ...
    Tw_s, result.DG_rob, result.DA_rob, result.DT_bar_rob, result.DT_rob, ...
    case_row.t0_worst_DG_s, case_row.t0_worst_DA_s, case_row.t0_worst_DT_s, case_row.dt_max_s, ...
    is_feasible_truth, dominant_metric, ...
    'VariableNames', {'baseline_case_id', 'baseline_case_family', ...
    'baseline_theta_h_km', 'baseline_theta_i_deg', 'baseline_theta_P', 'baseline_theta_T', 'baseline_theta_F', 'baseline_theta_Ns', ...
    'baseline_Tw_s', 'DG_worst_truth', 'DA_worst_truth', 'DT_bar_worst', 'DT_worst_truth', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dt_max_at_t0T_star_s', 'is_feasible_truth', 'dominant_metric'});

out = struct();
out.cfg = cfg;
out.theta_baseline = theta;
out.case_selection = selection;
out.summary_table = summary_table;
out.case_table = result.case_table;
out.window_table = table();
out.files = struct();
out.eval_result = result;
end

function theta = local_resolve_theta(cfg, overrides)
theta = cfg.milestones.baseline_theta;
if isfield(cfg.milestones, 'MA') && isfield(cfg.milestones.MA, 'theta')
    theta = cfg.milestones.MA.theta;
end
if isfield(overrides, 'theta') && isstruct(overrides.theta)
    theta = milestone_common_merge_structs(theta, overrides.theta);
end
end

function Tw_s = local_resolve_Tw(cfg, overrides)
Tw_s = cfg.milestones.Tw_baseline;
if isfield(cfg.milestones, 'MA') && isfield(cfg.milestones.MA, 'Tw_s')
    Tw_s = cfg.milestones.MA.Tw_s;
end
if isfield(overrides, 'Tw_s') && ~isempty(overrides.Tw_s)
    Tw_s = overrides.Tw_s;
end
end

function trajs_in = local_build_selected_casebank(selection, cfg)
case_i = selection.case_struct;
traj_i = propagate_hgv_case_stage02(case_i, cfg);
val_i = validate_hgv_trajectory_stage02(traj_i, cfg);
sum_i = summarize_hgv_case_stage02(case_i, traj_i, val_i);

trajs_in = struct();
trajs_in.case = case_i;
trajs_in.traj = traj_i;
trajs_in.validation = val_i;
trajs_in.summary = sum_i;
end

function row = local_build_theta_row(theta)
row = struct();
row.h_km = theta.h_km;
row.i_deg = theta.i_deg;
row.P = theta.P;
row.T = theta.T;
row.F = theta.F;
row.Ns = theta.P * theta.T;
end
