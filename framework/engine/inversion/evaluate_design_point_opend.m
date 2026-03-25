function result = evaluate_design_point_opend(design_row, trajs_in, gamma_eff_scalar, engine_cfg, eval_ctx)
%EVALUATE_DESIGN_POINT_OPEND Evaluate one design point under OpenD (D_G only).
% Inputs:
%   design_row        : struct or single-row table with h_km, i_deg, P, T, F
%   trajs_in          : target-family struct array with fields .case and .traj
%   gamma_eff_scalar  : scalar geometry threshold
%   engine_cfg        : engine configuration tree; defaults to default_params()
%   eval_ctx          : optional context with fields t_s_common and hard_order
%
% Output:
%   result            : OpenD evaluation result struct

if nargin < 4 || isempty(engine_cfg)
    engine_cfg = default_params();
end
if nargin < 5
    eval_ctx = [];
end

row = legacy_eval_support_common_impl('normalize_design_row', design_row);
ctx = legacy_eval_support_common_impl('build_eval_context', trajs_in, engine_cfg, eval_ctx);

t_s_common = ctx.t_s_common;
hard_order = ctx.hard_order;

cfg_eval = engine_cfg;
cfg_eval.stage04.gamma_req = gamma_eff_scalar;

walker = build_single_layer_walker(row, cfg_eval);
satbank = propagate_constellation(walker, t_s_common, cfg_eval);

nCase = numel(trajs_in);

case_id = strings(nCase, 1);
lambda_worst = nan(nCase, 1);
DG_rob_case = nan(nCase, 1);
pass_flag = false(nCase, 1);
t0_worst = nan(nCase, 1);
mean_vis = nan(nCase, 1);
dual_ratio = nan(nCase, 1);

n_evaluated = 0;
failed_early = false;

for kk = 1:nCase
    k = hard_order(kk);
    traj_case = trajs_in(k);

    vis_case = compute_visibility_matrix(traj_case, satbank, cfg_eval);
    window_case = compute_window_metric(vis_case, satbank, cfg_eval);
    s_win = summarize_worst_window(window_case);

    case_id(k) = string(traj_case.case.case_id);
    lambda_worst(k) = s_win.lambda_min_worst;
    DG_rob_case(k) = s_win.lambda_min_worst / gamma_eff_scalar;
    pass_flag(k) = (DG_rob_case(k) >= cfg_eval.stage05.require_D_G_min);
    t0_worst(k) = s_win.t0_worst_s;

    mean_vis(k) = mean(vis_case.num_visible, 'omitnan');
    dual_ratio(k) = mean(vis_case.dual_coverage_mask, 'omitnan');

    n_evaluated = n_evaluated + 1;

    if cfg_eval.stage05.use_early_stop
        if cfg_eval.stage05.require_pass_ratio >= 1.0 && (~pass_flag(k))
            failed_early = true;
            break;
        end
    end
end

for k = 1:nCase
    if strlength(case_id(k)) == 0
        case_id(k) = string(trajs_in(k).case.case_id);
    end
end

case_table = table(case_id, lambda_worst, DG_rob_case, pass_flag, t0_worst, mean_vis, dual_ratio, ...
    'VariableNames', {'case_id', 'lambda_worst', 'DG_rob', 'pass_flag', 't0_worst_s', 'mean_vis', 'dual_ratio'});

lambda_valid = lambda_worst(isfinite(lambda_worst));
DG_valid = DG_rob_case(isfinite(DG_rob_case));
pass_valid = pass_flag(isfinite(DG_rob_case));

if isempty(lambda_valid)
    lambda_worst_min = NaN;
    lambda_worst_mean = NaN;
else
    lambda_worst_min = min(lambda_valid);
    lambda_worst_mean = mean(lambda_valid, 'omitnan');
end

if isempty(DG_valid)
    DG_rob = NaN;
    DG_mean = NaN;
    pass_ratio = NaN;
    worst_case_id_DG = "";
else
    finite_idx = find(isfinite(DG_rob_case));
    [DG_rob, idx_min] = min(DG_valid);
    DG_mean = mean(DG_valid, 'omitnan');
    worst_idx = finite_idx(idx_min);
    if isempty(worst_idx) || worst_idx < 1 || worst_idx > nCase
        worst_case_id_DG = "";
    else
        worst_case_id_DG = case_id(worst_idx);
    end

    if failed_early
        pass_ratio = sum(pass_valid) / nCase;
    else
        pass_ratio = mean(pass_valid, 'omitnan');
    end
end

joint_margin = DG_rob;
feasible_flag = (pass_ratio >= cfg_eval.stage05.require_pass_ratio) && ...
                (DG_rob >= cfg_eval.stage05.require_D_G_min);

switch string(cfg_eval.stage05.rank_rule)
    case "min_Ns_then_max_DG"
        rank_score = row.Ns - 1e-3 * DG_mean;
    otherwise
        rank_score = row.Ns - 1e-3 * DG_mean;
end

result = struct();
result.walker = walker;
result.satbank = satbank;
result.case_table = case_table;
result.lambda_worst_min = lambda_worst_min;
result.lambda_worst_mean = lambda_worst_mean;
result.DG_rob = DG_rob;
result.DG_mean = DG_mean;
result.joint_margin = joint_margin;
result.pass_ratio = pass_ratio;
result.feasible_flag = feasible_flag;
result.worst_case_id_DG = char(worst_case_id_DG);
result.rank_score = rank_score;
result.n_case_total = nCase;
result.n_case_evaluated = n_evaluated;
result.failed_early = failed_early;
end
