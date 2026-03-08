function result = evaluate_single_layer_walker_stage06(row, trajs_in, gamma_req, cfg, hard_order)
    %EVALUATE_SINGLE_LAYER_WALKER_STAGE06
    % Evaluate one Walker design against Stage06 heading-extended family.
    %
    % Input:
    %   row        : one row from Stage06 search grid
    %   trajs_in   : heading-extended family
    %   gamma_req  : inherited from Stage04
    %   cfg        : default params
    %   hard_order : optional index order for heading-extended cases
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
    
        if nargin < 5 || isempty(hard_order)
            hard_order = (1:numel(trajs_in)).';
        end
    
        % ------------------------------------------------------------
        % Build time grid from input family trajectories
        % ------------------------------------------------------------
        t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
        t_max = max(t_end_all);
        dt = cfg.stage02.Ts_s;
        t_s_common = (0:dt:t_max).';
    
        % ------------------------------------------------------------
        % Build Walker by patching Stage03 config
        % ------------------------------------------------------------
        cfg_eval = cfg;
        cfg_eval.stage03.h_km = row.h_km;
        cfg_eval.stage03.i_deg = row.i_deg;
        cfg_eval.stage03.P = row.P;
        cfg_eval.stage03.T = row.T;
        cfg_eval.stage03.F = row.F;
        cfg_eval.stage04.gamma_req = gamma_req;
    
        walker = build_single_layer_walker_stage03(cfg_eval);
        satbank = propagate_constellation_stage03(walker, t_s_common);
    
        % ------------------------------------------------------------
        % Run heading-extended family
        % ------------------------------------------------------------
        nCase = numel(trajs_in);
    
        case_id = strings(nCase,1);
        entry_id = nan(nCase,1);
        heading_offset_deg = nan(nCase,1);
        heading_label = strings(nCase,1);
    
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
            los_geom = compute_los_geometry_stage03(vis_case, satbank);
            s_vis = summarize_visibility_case_stage03(vis_case, los_geom);
    
            window_case = scan_worst_window_stage04(vis_case, satbank, cfg_eval);
            s_win = summarize_window_case_stage04(window_case);
    
            case_id(k) = string(traj_case.case.case_id);
    
            if isfield(traj_case.case, 'entry_id')
                entry_id(k) = traj_case.case.entry_id;
            elseif isfield(traj_case.case, 'entry_point_id')
                entry_id(k) = traj_case.case.entry_point_id;
            end
    
            if isfield(traj_case.case, 'heading_offset_deg')
                heading_offset_deg(k) = traj_case.case.heading_offset_deg;
            end
    
            if isfield(traj_case.case, 'heading_label')
                heading_label(k) = string(traj_case.case.heading_label);
            end
    
            lambda_worst(k) = s_win.lambda_min_worst;
            D_G(k) = s_win.lambda_min_worst / gamma_req;
            pass_flag(k) = (D_G(k) >= cfg.stage06.require_D_G_min);
            t0_worst(k) = s_win.t0_worst_s;
    
            mean_vis(k) = s_vis.mean_num_visible;
            dual_ratio(k) = s_vis.dual_coverage_ratio;
    
            n_evaluated = n_evaluated + 1;
    
            % --------------------------------------------------------
            % Early stop
            % --------------------------------------------------------
            if cfg.stage06.use_early_stop
                if cfg.stage06.require_pass_ratio >= 1.0 && (~pass_flag(k))
                    failed_early = true;
                    break;
                end
            end
        end
    
        for k = 1:nCase
            if strlength(case_id(k)) == 0
                case_id(k) = string(trajs_in(k).case.case_id);
            end
            if strlength(heading_label(k)) == 0
                if isfield(trajs_in(k).case, 'heading_label')
                    heading_label(k) = string(trajs_in(k).case.heading_label);
                else
                    heading_label(k) = "";
                end
            end
            if ~isfinite(entry_id(k))
                if isfield(trajs_in(k).case, 'entry_id')
                    entry_id(k) = trajs_in(k).case.entry_id;
                elseif isfield(trajs_in(k).case, 'entry_point_id')
                    entry_id(k) = trajs_in(k).case.entry_point_id;
                end
            end
            if ~isfinite(heading_offset_deg(k)) && isfield(trajs_in(k).case, 'heading_offset_deg')
                heading_offset_deg(k) = trajs_in(k).case.heading_offset_deg;
            end
        end
    
        case_table = table( ...
            case_id, entry_id, heading_offset_deg, heading_label, ...
            lambda_worst, D_G, pass_flag, t0_worst, mean_vis, dual_ratio);
    
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
    
        feasible_flag = (pass_ratio >= cfg.stage06.require_pass_ratio) && ...
                        (D_G_min >= cfg.stage06.require_D_G_min);
    
        switch string(cfg.stage06.rank_rule)
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