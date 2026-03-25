function result = evaluate_design_point_closedd(design_row, trajs_in, gamma_eff_scalar, engine_cfg, eval_ctx)
%EVALUATE_DESIGN_POINT_CLOSEDD Evaluate one design point under ClosedD.
% Inputs:
%   design_row        : struct or single-row table with h_km, i_deg, P, T, F
%   trajs_in          : target-family struct array with fields .case and .traj
%   gamma_eff_scalar  : scalar geometry threshold
%   engine_cfg        : engine configuration tree; defaults to default_params()
%   eval_ctx          : optional shared context
%
% Output:
%   result            : ClosedD evaluation result struct

if nargin < 4 || isempty(engine_cfg)
    engine_cfg = default_params();
end
if nargin < 5
    eval_ctx = [];
end

row = legacy_eval_support_common_impl('normalize_design_row', design_row);
ctx = legacy_eval_support_common_impl('build_stage09_context', trajs_in, engine_cfg, gamma_eff_scalar, eval_ctx);
cfg = ctx.cfg;
t_s_common = ctx.t_s_common;

hard_order = (1:numel(trajs_in)).';
if isfield(ctx, 'hard_order') && ~isempty(ctx.hard_order)
    hard_order = ctx.hard_order(:);
end

cfg_eval = cfg;
cfg_eval.stage09.gamma_eff_scalar = ctx.gamma_eff_scalar;

if isfield(cfg_eval.stage09, 'Tw_star_s') && ~isempty(cfg_eval.stage09.Tw_star_s)
    cfg_eval.stage04.Tw_s = cfg_eval.stage09.Tw_star_s;
end

walker = build_single_layer_walker(row, cfg_eval);
satbank = propagate_constellation(walker, t_s_common, cfg_eval);

nCase = ctx.nCase;

case_id = ctx.case_id;
family = ctx.family;
subfamily = ctx.subfamily;
entry_id = ctx.entry_id;
heading_offset_deg = ctx.heading_offset_deg;

DG_case = nan(nCase, 1);
DA_case = nan(nCase, 1);
DT_bar_case = nan(nCase, 1);
DT_case = nan(nCase, 1);
joint_case_margin = nan(nCase, 1);
pass_flag_case = false(nCase, 1);

lambda_worst = nan(nCase, 1);
sigma_A_proj_worst = nan(nCase, 1);
t0_worst_DG = nan(nCase, 1);
t0_worst_DA = nan(nCase, 1);
t0_worst_DT = nan(nCase, 1);

dt_max_s = nan(nCase, 1);
mean_vis = nan(nCase, 1);
dual_ratio = nan(nCase, 1);
custody_ratio = nan(nCase, 1);
fail_tag_case = strings(nCase, 1);

n_evaluated = 0;
failed_early = false;

for kk = 1:nCase
    k = hard_order(kk);
    traj_case = trajs_in(k);

    vis_case = compute_visibility_matrix(traj_case, satbank, cfg_eval);
    los_geom = compute_geometry_series(vis_case, satbank);
    s_vis = summarize_visibility_case(vis_case, los_geom);

    window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);
    i0 = window_grid.start_idx(:);
    i1 = window_grid.end_idx(:);
    nW = window_grid.num_windows;

    DG_w = nan(nW, 1);
    DA_w = nan(nW, 1);
    lambda_min_w = nan(nW, 1);
    sigma_A_proj_w = nan(nW, 1);

    for iw = 1:nW
        Wr = build_window_info_matrix_stage04(vis_case, i0(iw), i1(iw), satbank, cfg_eval);
        Wr = 0.5 * (Wr + Wr.');

        wm = compute_window_metrics_stage09(Wr, cfg_eval);

        DG_w(iw) = wm.DG;
        DA_w(iw) = wm.DA;
        lambda_min_w(iw) = wm.lambda_min_eff;
        sigma_A_proj_w(iw) = wm.sigma_A_proj;
    end

    valid_metric_window = (DG_w > 0) | (DA_w > 0);

    if any(valid_metric_window)
        DG_w_eff = DG_w;
        DG_w_eff(~valid_metric_window) = inf;
        [DG_case(k), idx_DG] = min(DG_w_eff);

        DA_w_eff = DA_w;
        DA_w_eff(~valid_metric_window) = inf;
        [DA_case(k), idx_DA] = min(DA_w_eff);

        lambda_worst(k) = lambda_min_w(idx_DG);
        sigma_A_proj_worst(k) = sigma_A_proj_w(idx_DA);
        t0_worst_DG(k) = window_grid.t0_s(idx_DG);
        t0_worst_DA(k) = window_grid.t0_s(idx_DA);
    else
        DG_case(k) = 0;
        DA_case(k) = 0;

        lambda_worst(k) = 0;
        sigma_A_proj_worst(k) = inf;
        t0_worst_DG(k) = window_grid.t0_s(1);
        t0_worst_DA(k) = window_grid.t0_s(1);
    end

    gap = compute_gap_metrics_stage09(vis_case.t_s, vis_case.num_visible, cfg_eval);
    DT_bar_case(k) = gap.DT_bar_window;
    DT_case(k) = gap.DT_window;
    dt_max_s(k) = gap.dt_max_window;
    custody_ratio(k) = gap.custody_ratio;
    t0_worst_DT(k) = vis_case.t_s(1);

    joint_case_margin(k) = min([DG_case(k), DA_case(k), DT_case(k)]);
    pass_flag_case(k) = ...
        (DG_case(k) >= cfg.stage09.require_DG_min) && ...
        (DA_case(k) >= cfg.stage09.require_DA_min) && ...
        (DT_case(k) >= cfg.stage09.require_DT_min);

    fail_tag_case(k) = local_case_fail_tag(DG_case(k), DA_case(k), DT_case(k), cfg.stage09);

    mean_vis(k) = s_vis.mean_num_visible;
    dual_ratio(k) = s_vis.dual_coverage_ratio;

    n_evaluated = n_evaluated + 1;

    if cfg.stage09.use_early_stop
        if cfg.stage09.require_pass_ratio >= 1.0 && ~pass_flag_case(k)
            failed_early = true;
            break;
        end
    end
end

for k = 1:nCase
    if strlength(fail_tag_case(k)) == 0
        fail_tag_case(k) = "";
    end
end

case_table = table( ...
    case_id, family, subfamily, entry_id, heading_offset_deg, ...
    DG_case, DA_case, DT_bar_case, DT_case, joint_case_margin, pass_flag_case, ...
    lambda_worst, sigma_A_proj_worst, t0_worst_DG, t0_worst_DA, t0_worst_DT, ...
    dt_max_s, mean_vis, dual_ratio, custody_ratio, fail_tag_case, ...
    'VariableNames', { ...
        'case_id', 'family', 'subfamily', 'entry_id', 'heading_offset_deg', ...
        'DG', 'DA', 'DT_bar', 'DT', 'joint_case_margin', 'pass_flag_case', ...
        'lambda_worst', 'sigma_A_proj_worst', 't0_worst_DG_s', 't0_worst_DA_s', 't0_worst_DT_s', ...
        'dt_max_s', 'mean_num_visible', 'dual_coverage_ratio', 'custody_ratio', 'fail_tag_case'});

DG_valid = DG_case(isfinite(DG_case));
DA_valid = DA_case(isfinite(DA_case));
DT_bar_valid = DT_bar_case(isfinite(DT_bar_case));
DT_valid = DT_case(isfinite(DT_case));
pass_valid = pass_flag_case(~cellfun(@isempty, cellstr(case_id)));

if isempty(DG_valid), DG_rob = NaN; else, DG_rob = min(DG_valid); end
if isempty(DA_valid), DA_rob = NaN; else, DA_rob = min(DA_valid); end
if isempty(DT_bar_valid), DT_bar_rob = NaN; else, DT_bar_rob = min(DT_bar_valid); end
if isempty(DT_valid), DT_rob = NaN; else, DT_rob = min(DT_valid); end

joint_margin = min([DG_rob, DA_rob, DT_rob]);

if isempty(pass_valid)
    pass_ratio = NaN;
else
    if failed_early
        pass_ratio = sum(pass_valid) / nCase;
    else
        pass_ratio = mean(pass_valid, 'omitnan');
    end
end

feasible_flag = ...
    (pass_ratio >= cfg.stage09.require_pass_ratio) && ...
    (DG_rob >= cfg.stage09.require_DG_min) && ...
    (DA_rob >= cfg.stage09.require_DA_min) && ...
    (DT_rob >= cfg.stage09.require_DT_min);

worst_case_id_DG = local_pick_case_id(case_table, 'DG', 'min');
worst_case_id_DA = local_pick_case_id(case_table, 'DA', 'min');
worst_case_id_DT = local_pick_case_id(case_table, 'DT', 'min');

dominant_fail_tag = local_theta_fail_tag(DG_rob, DA_rob, DT_rob, cfg.stage09);

switch string(cfg.stage09.rank_rule)
    case "min_Ns_then_max_joint_margin"
        rank_score = row.Ns - 1e-3 * joint_margin;
    otherwise
        rank_score = row.Ns - 1e-3 * joint_margin;
end

result = struct();
result.walker = walker;
result.satbank = satbank;
result.case_table = case_table;
result.DG_rob = DG_rob;
result.DA_rob = DA_rob;
result.DT_bar_rob = DT_bar_rob;
result.DT_rob = DT_rob;
result.joint_margin = joint_margin;
result.pass_ratio = pass_ratio;
result.feasible_flag = feasible_flag;
result.dominant_fail_tag = char(dominant_fail_tag);
result.worst_case_id_DG = char(worst_case_id_DG);
result.worst_case_id_DA = char(worst_case_id_DA);
result.worst_case_id_DT = char(worst_case_id_DT);
result.rank_score = rank_score;
result.n_case_total = nCase;
result.n_case_evaluated = n_evaluated;
result.failed_early = failed_early;
end

function tag = local_case_fail_tag(DG, DA, DT, s9)
g = DG < s9.require_DG_min;
a = DA < s9.require_DA_min;
t = DT < s9.require_DT_min;
tag = local_join_fail_tag(g, a, t);
end

function tag = local_theta_fail_tag(DG, DA, DT, s9)
g = DG < s9.require_DG_min;
a = DA < s9.require_DA_min;
t = DT < s9.require_DT_min;
tag = local_join_fail_tag(g, a, t);
end

function tag = local_join_fail_tag(g, a, t)
if ~(g || a || t)
    tag = "OK";
    return;
end

pieces = strings(0, 1);
if g, pieces(end+1, 1) = "G"; end %#ok<AGROW>
if a, pieces(end+1, 1) = "A"; end %#ok<AGROW>
if t, pieces(end+1, 1) = "T"; end %#ok<AGROW>

tag = join(pieces, "");
tag = string(tag);
end

function cid = local_pick_case_id(case_table, metric_name, mode)
cid = "";
if ~istable(case_table) || height(case_table) < 1
    return;
end

x = case_table.(metric_name);
valid = isfinite(x);
if ~any(valid)
    return;
end

switch lower(string(mode))
    case "min"
        xv = x;
        xv(~valid) = inf;
        [~, idx] = min(xv);
    case "max"
        xv = x;
        xv(~valid) = -inf;
        [~, idx] = max(xv);
    otherwise
        error('Unknown mode: %s', string(mode));
end

cid = case_table.case_id(idx);
end
