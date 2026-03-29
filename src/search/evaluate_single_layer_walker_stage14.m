function result = evaluate_single_layer_walker_stage14(row, trajs_in, gamma_req, cfg, hard_order, eval_context)
%EVALUATE_SINGLE_LAYER_WALKER_STAGE14
% Evaluate one Stage14.1 design point on nominal family using Stage03+Stage04
% chain, with a relative RAAN/orientation offset.
%
% Input:
%   row         : one table row from Stage14 grid
%   trajs_in    : trajbank.nominal from Stage02
%   gamma_req   : fixed threshold inherited from latest Stage04
%   cfg         : config (Stage14 fields)
%   hard_order  : optional case evaluation order
%   eval_context: optional precomputed common time grid
%
% Output:
%   result struct with fields:
%     walker
%     satbank
%     case_table
%     lambda_worst_min
%     lambda_worst_mean
%     D_G_min
%     D_G_mean
%     pass_ratio
%     feasible_flag
%     rank_score
%     n_case_total
%     n_case_evaluated
%     failed_early

    if nargin < 5 || isempty(hard_order)
        hard_order = (1:numel(trajs_in)).';
    end
    if nargin < 6 || isempty(eval_context)
        eval_context = local_build_eval_context(trajs_in, cfg);
    end

    t_s_common = eval_context.t_s_common;

    cfg_eval = cfg;
    cfg_eval.stage03.h_km = row.h_km;
    cfg_eval.stage03.i_deg = row.i_deg;
    cfg_eval.stage03.P = row.P;
    cfg_eval.stage03.T = row.T;
    cfg_eval.stage03.F = row.F;
    cfg_eval.stage04.gamma_req = gamma_req;

    walker = build_single_layer_walker_stage03(cfg_eval);
    walker = local_apply_raan_offset(walker, row.RAAN_deg);
    satbank = propagate_constellation_stage03(walker, t_s_common);

    nCase = numel(trajs_in);

    case_id = strings(nCase,1);
    lambda_worst = nan(nCase,1);
    D_G = nan(nCase,1);
    pass_flag = false(nCase,1);
    t0_worst = nan(nCase,1);
    mean_vis = nan(nCase,1);
    dual_ratio = nan(nCase,1);

    n_evaluated = 0;
    failed_early = false;

    for kk = 1:nCase
        k = hard_order(kk);
        traj_case = trajs_in(k);

        vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
        window_case = scan_worst_window_stage04(vis_case, satbank, cfg_eval);
        s_win = summarize_window_case_stage04(window_case);

        case_id(k) = string(traj_case.case.case_id);
        lambda_worst(k) = s_win.lambda_min_worst;
        D_G(k) = s_win.lambda_min_worst / gamma_req;
        pass_flag(k) = (D_G(k) >= cfg.stage14.require_D_G_min);
        t0_worst(k) = s_win.t0_worst_s;

        mean_vis(k) = mean(vis_case.num_visible, 'omitnan');
        dual_ratio(k) = mean(vis_case.dual_coverage_mask, 'omitnan');

        n_evaluated = n_evaluated + 1;

        if cfg.stage14.use_early_stop
            if cfg.stage14.require_pass_ratio >= 1.0 && (~pass_flag(k))
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

    case_table = table(case_id, lambda_worst, D_G, pass_flag, t0_worst, mean_vis, dual_ratio);

    lambda_worst_valid = lambda_worst(isfinite(lambda_worst));
    D_G_valid = D_G(isfinite(D_G));
    pass_flag_valid = pass_flag(isfinite(D_G));

    if isempty(lambda_worst_valid)
        lambda_worst_min = NaN;
        lambda_worst_mean = NaN;
    else
        lambda_worst_min = min(lambda_worst_valid);
        lambda_worst_mean = mean(lambda_worst_valid, 'omitnan');
    end

    if isempty(D_G_valid)
        D_G_min = NaN;
        D_G_mean = NaN;
        pass_ratio = NaN;
    else
        D_G_min = min(D_G_valid);
        D_G_mean = mean(D_G_valid, 'omitnan');

        if failed_early
            n_pass = sum(pass_flag_valid);
            pass_ratio = n_pass / nCase;
        else
            pass_ratio = mean(pass_flag_valid, 'omitnan');
        end
    end

    feasible_flag = (pass_ratio >= cfg.stage14.require_pass_ratio) && ...
                    (D_G_min >= cfg.stage14.require_D_G_min);

    switch string(cfg.stage14.rank_rule)
        case "min_Ns_then_max_DG"
            rank_score = row.Ns - 1e-3 * D_G_mean;
        otherwise
            rank_score = row.Ns - 1e-3 * D_G_mean;
    end

    result = struct();
    result.walker = walker;
    result.satbank = satbank;
    result.case_table = case_table;

    result.lambda_worst_min = lambda_worst_min;
    result.lambda_worst_mean = lambda_worst_mean;
    result.D_G_min = D_G_min;
    result.D_G_mean = D_G_mean;
    result.pass_ratio = pass_ratio;
    result.feasible_flag = feasible_flag;
    result.rank_score = rank_score;
    result.n_case_total = nCase;
    result.n_case_evaluated = n_evaluated;
    result.failed_early = failed_early;
end

function walker2 = local_apply_raan_offset(walker, raan_offset_deg)
    walker2 = walker;
    for k = 1:numel(walker2.sat)
        walker2.sat(k).raan_deg = mod(walker2.sat(k).raan_deg + raan_offset_deg, 360);
    end
end

function eval_context = local_build_eval_context(trajs_in, cfg)
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;

    eval_context = struct();
    eval_context.t_s_common = (0:dt:t_max).';
end
