function result = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx, hard_order)
%EVALUATE_SINGLE_LAYER_WALKER_STAGE09
% Evaluate one Walker design against the full Stage09 case family.
%
% Input:
%   row              : one row from Stage09 search grid
%   trajs_in         : trajectory family / casebank
%   gamma_eff_scalar : scalar geometric threshold used by DG
%   cfg              : default params (already prepared by stage09_prepare_cfg)
%   eval_ctx         : optional shared context from build_stage09_eval_context
%   hard_order       : optional case visiting order
%
% Output:
%   result struct with fields:
%     walker
%     satbank
%     case_table
%     DG_rob
%     DA_rob
%     DT_rob
%     joint_margin
%     pass_ratio
%     feasible_flag
%     dominant_fail_tag
%     worst_case_id_DG
%     worst_case_id_DA
%     worst_case_id_DT
%     rank_score
%     n_case_total
%     n_case_evaluated
%     failed_early

    if nargin < 5
        eval_ctx = [];
    end
    if nargin < 6 || isempty(hard_order)
        hard_order = (1:numel(trajs_in)).';
    end

    if isempty(eval_ctx)
        eval_ctx = build_stage09_eval_context(trajs_in, cfg, gamma_eff_scalar);
    end
    cfg = eval_ctx.cfg;
    t_s_common = eval_ctx.t_s_common;

    % ------------------------------------------------------------
    % Build Walker by patching Stage03 config
    % ------------------------------------------------------------
    cfg_eval = cfg;
    cfg_eval.stage03.h_km = row.h_km;
    cfg_eval.stage03.i_deg = row.i_deg;
    cfg_eval.stage03.P = row.P;
    cfg_eval.stage03.T = row.T;
    cfg_eval.stage03.F = row.F;

    % Freeze Stage09 geometric threshold for the current evaluator
    cfg_eval.stage09.gamma_eff_scalar = eval_ctx.gamma_eff_scalar;

    % Use Tw_star inherited/frozen by Stage09.1
    if isfield(cfg_eval.stage09, 'Tw_star_s') && ~isempty(cfg_eval.stage09.Tw_star_s)
        cfg_eval.stage04.Tw_s = cfg_eval.stage09.Tw_star_s;
    end

    walker = build_single_layer_walker_stage03(cfg_eval);
    satbank = propagate_constellation_stage03(walker, t_s_common);

    % ------------------------------------------------------------
    % Evaluate full case family
    % ------------------------------------------------------------
    nCase = eval_ctx.nCase;

    case_id = eval_ctx.case_id;
    family = eval_ctx.family;
    subfamily = eval_ctx.subfamily;
    entry_id = eval_ctx.entry_id;
    heading_offset_deg = eval_ctx.heading_offset_deg;

    DG_case = nan(nCase,1);
    DA_case = nan(nCase,1);
    DT_bar_case = nan(nCase,1);
    DT_case = nan(nCase,1);
    joint_case_margin = nan(nCase,1);
    pass_flag_case = false(nCase,1);

    lambda_worst = nan(nCase,1);
    sigma_A_proj_worst = nan(nCase,1);
    t0_worst_DG = nan(nCase,1);
    t0_worst_DA = nan(nCase,1);
    t0_worst_DT = nan(nCase,1);

    dt_max_s = nan(nCase,1);
    mean_vis = nan(nCase,1);
    dual_ratio = nan(nCase,1);
    custody_ratio = nan(nCase,1);
    fail_tag_case = strings(nCase,1);

    if cfg.stage09.save_case_window_bank
        case_window_bank = cell(nCase,1);
    else
        case_window_bank = [];
    end

    n_evaluated = 0;
    failed_early = false;

    for kk = 1:nCase
        k = hard_order(kk);
        traj_case = trajs_in(k);

        vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
        los_geom = compute_los_geometry_stage03(vis_case, satbank);
        s_vis = summarize_visibility_case_stage03(vis_case, los_geom);

                % --------------------------------------------------------
        % Build all window-level Wr and evaluate DG/DA per window
        % --------------------------------------------------------
        % Current repository truth:
        %   Stage04 constructs Wr directly per window via
        %   build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg)
        % rather than through a separate Wt timeseries helper.
        window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);
        i0 = window_grid.start_idx(:);
        i1 = window_grid.end_idx(:);
        nW = window_grid.num_windows;

        DG_w = nan(nW,1);
        DA_w = nan(nW,1);
        lambda_min_w = nan(nW,1);
        sigma_A_proj_w = nan(nW,1);

        if cfg.stage09.save_case_window_bank
            wb = struct();
            wb.t0_s = window_grid.t0_s(:);
            wb.t1_s = window_grid.t1_s(:);
            wb.lambda_min = nan(nW,1);
            wb.DG = nan(nW,1);
            wb.sigma_A_proj = nan(nW,1);
            wb.DA = nan(nW,1);
        else
            wb = [];
        end

        for iw = 1:nW
            Wr = build_window_info_matrix_stage04(vis_case, i0(iw), i1(iw), satbank, cfg_eval);
            Wr = 0.5 * (Wr + Wr.');   % enforce symmetry for safety

            wm = compute_window_metrics_stage09(Wr, cfg_eval);

            DG_w(iw) = wm.DG;
            DA_w(iw) = wm.DA;
            lambda_min_w(iw) = wm.lambda_min_eff;
            sigma_A_proj_w(iw) = wm.sigma_A_proj;

            if cfg.stage09.save_case_window_bank
                wb.lambda_min(iw) = wm.lambda_min_eff;
                wb.DG(iw) = wm.DG;
                wb.sigma_A_proj(iw) = wm.sigma_A_proj;
                wb.DA(iw) = wm.DA;
            end
        end

                % --------------------------------------------------------
        % For DG / DA, do NOT let pure zero-information windows dominate.
        % DT already handles full-time outage / broken custody.
        %
        % Therefore:
        %   - DG/DA are taken over "effective windows" only
        %   - an effective window is one with some non-zero usable information
        %     after Stage09.2 metric extraction
        % --------------------------------------------------------
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
            % No effective-information window exists for this case.
            % In that situation:
            %   - DG/DA are set to zero explicitly
            %   - DT will still carry the full outage penalty
            DG_case(k) = 0;
            DA_case(k) = 0;

            lambda_worst(k) = 0;
            sigma_A_proj_worst(k) = inf;
            t0_worst_DG(k) = window_grid.t0_s(1);
            t0_worst_DA(k) = window_grid.t0_s(1);
        end

        % --------------------------------------------------------
        % D_T from visibility gaps
        % --------------------------------------------------------
        gap = compute_gap_metrics_stage09(vis_case.t_s, vis_case.num_visible, cfg_eval);
        DT_bar_case(k) = gap.DT_bar_window;
        DT_case(k) = gap.DT_window;
        dt_max_s(k) = gap.dt_max_window;
        custody_ratio(k) = gap.custody_ratio;
        t0_worst_DT(k) = vis_case.t_s(1);

        % --------------------------------------------------------
        % Summary fields
        % --------------------------------------------------------
        joint_case_margin(k) = min([DG_case(k), DA_case(k), DT_case(k)]);
        pass_flag_case(k) = ...
            (DG_case(k) >= cfg.stage09.require_DG_min) && ...
            (DA_case(k) >= cfg.stage09.require_DA_min) && ...
            (DT_case(k) >= cfg.stage09.require_DT_min);

        fail_tag_case(k) = local_case_fail_tag( ...
            DG_case(k), DA_case(k), DT_case(k), cfg.stage09);

        mean_vis(k) = s_vis.mean_num_visible;
        dual_ratio(k) = s_vis.dual_coverage_ratio;

        if cfg.stage09.save_case_window_bank
            case_window_bank{k} = wb;
        end

        n_evaluated = n_evaluated + 1;

        % --------------------------------------------------------
        % Early stop
        % --------------------------------------------------------
        if cfg.stage09.use_early_stop
            if cfg.stage09.require_pass_ratio >= 1.0 && ~pass_flag_case(k)
                failed_early = true;
                break;
            end
        end
    end

    % Fill metadata for not-yet-evaluated cases after early stop
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

    metrics = aggregate_stage09_case_table(case_table, row, cfg, failed_early, nCase, n_evaluated);

    result = struct();
    result.walker = walker;
    result.satbank = satbank;
    result.case_table = case_table;

    if cfg.stage09.save_case_window_bank
        result.case_window_bank = case_window_bank;
    end

    result.DG_rob = metrics.DG_rob;
    result.DA_rob = metrics.DA_rob;
    result.DT_bar_rob = metrics.DT_bar_rob;
    result.DT_rob = metrics.DT_rob;
    result.joint_margin = metrics.joint_margin;
    result.pass_ratio = metrics.pass_ratio;
    result.feasible_flag = metrics.feasible_flag;
    result.dominant_fail_tag = metrics.dominant_fail_tag;
    result.worst_case_id_DG = metrics.worst_case_id_DG;
    result.worst_case_id_DA = metrics.worst_case_id_DA;
    result.worst_case_id_DT = metrics.worst_case_id_DT;
    result.rank_score = metrics.rank_score;

    result.n_case_total = metrics.n_case_total;
    result.n_case_evaluated = metrics.n_case_evaluated;
    result.failed_early = metrics.failed_early;
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

    pieces = strings(0,1);
    if g, pieces(end+1,1) = "G"; end %#ok<AGROW>
    if a, pieces(end+1,1) = "A"; end %#ok<AGROW>
    if t, pieces(end+1,1) = "T"; end %#ok<AGROW>

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
