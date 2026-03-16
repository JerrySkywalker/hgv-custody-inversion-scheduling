function out = stage12B_truth_case_window_scan(cfg, overrides)
%STAGE12B_TRUTH_CASE_WINDOW_SCAN Compute full window-level truth curves for one case/theta pair.

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
cfg.stage09.run_tag = 'stage12B_truth_case_window_scan';

traj_case = local_build_selected_case(selection, cfg);
cfg_eval = cfg;
cfg_eval.stage03.h_km = theta.h_km;
cfg_eval.stage03.i_deg = theta.i_deg;
cfg_eval.stage03.P = theta.P;
cfg_eval.stage03.T = theta.T;
cfg_eval.stage03.F = theta.F;
cfg_eval.stage09.gamma_eff_scalar = 1.0;

walker = build_single_layer_walker_stage03(cfg_eval);
satbank = propagate_constellation_stage03(walker, traj_case.traj.t_s);
vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);

nW = window_grid.num_windows;
DG_window = nan(nW, 1);
DA_window = nan(nW, 1);
DT_bar_window = nan(nW, 1);
DT_window = nan(nW, 1);
dt_max_window_s = nan(nW, 1);

for iw = 1:nW
    idx0 = window_grid.start_idx(iw);
    idx1 = window_grid.end_idx(iw);

    Wr = build_window_info_matrix_stage04(vis_case, idx0, idx1, satbank, cfg_eval);
    Wr = 0.5 * (Wr + Wr.');
    wm = compute_window_metrics_stage09(Wr, cfg_eval);
    gap = compute_gap_metrics_stage09(vis_case.t_s(idx0:idx1), vis_case.num_visible(idx0:idx1), cfg_eval);

    DG_window(iw) = wm.DG;
    DA_window(iw) = wm.DA;
    DT_bar_window(iw) = gap.DT_bar_window;
    DT_window(iw) = gap.DT_window;
    dt_max_window_s(iw) = gap.dt_max_window;
end

[~, idxG] = min(DG_window);
[~, idxA] = min(DA_window);
[~, idxT] = min(DT_window);

window_table = table( ...
    repmat(string(selection.case_id), nW, 1), ...
    window_grid.t0_s(:), DG_window, DA_window, DT_bar_window, DT_window, ...
    dt_max_window_s, ...
    false(nW, 1), false(nW, 1), false(nW, 1), ...
    'VariableNames', {'case_id', 't0_s', 'DG_window', 'DA_window', 'DT_bar_window', 'DT_window', ...
    'dt_max_window_s', 'DG_is_worst', 'DA_is_worst', 'DT_is_worst'});
window_table.DG_is_worst(idxG) = true;
window_table.DA_is_worst(idxA) = true;
window_table.DT_is_worst(idxT) = true;

summary_table = table( ...
    string(selection.case_id), string(selection.case_family), ...
    DG_window(idxG), DA_window(idxA), DT_bar_window(idxT), DT_window(idxT), ...
    window_grid.t0_s(idxG), window_grid.t0_s(idxA), window_grid.t0_s(idxT), dt_max_window_s(idxT), ...
    'VariableNames', {'case_id', 'case_family', ...
    'DG_worst_truth', 'DA_worst_truth', 'DT_bar_worst', 'DT_worst_truth', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dt_max_at_t0T_star_s'});

out = struct();
out.cfg = cfg;
out.overrides = overrides;
out.case_selection = selection;
out.theta_baseline = theta;
out.window_table = window_table;
out.summary_table = summary_table;
out.vis_case = vis_case;
out.window_grid = window_grid;
out.files = struct();
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

function traj_case = local_build_selected_case(selection, cfg)
case_i = selection.case_struct;
traj_case = struct();
traj_case.case = case_i;
traj_case.traj = propagate_hgv_case_stage02(case_i, cfg);
traj_case.validation = validate_hgv_trajectory_stage02(traj_case.traj, cfg);
traj_case.summary = summarize_hgv_case_stage02(case_i, traj_case.traj, traj_case.validation);
end
