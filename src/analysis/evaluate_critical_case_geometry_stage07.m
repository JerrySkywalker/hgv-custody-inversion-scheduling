function result = evaluate_critical_case_geometry_stage07(case_item, reference_walker, gamma_req, cfg)
    %EVALUATE_CRITICAL_CASE_GEOMETRY_STAGE07
    % Evaluate one target case under a fixed reference Walker using
    % existing Stage03 + Stage04 pipeline.
    %
    % Input:
    %   case_item         : struct with fields case / traj / validation / summary
    %   reference_walker  : struct from Stage07.1
    %   gamma_req         : inherited threshold from Stage04
    %   cfg               : default params
    %
    % Output:
    %   result.diag_row   : one-row struct for table assembly
    %   result.visibility_summary
    %   result.window_summary
    %   result.walker
    %   result.satbank
    
        if nargin < 4 || isempty(cfg)
            cfg = default_params();
        end
    
        assert(isstruct(case_item) && isfield(case_item, 'traj'), ...
            'case_item must contain traj.');
        assert(isstruct(reference_walker), ...
            'reference_walker must be a struct.');
    
        % ------------------------------------------------------------
        % Build common time grid from target trajectory
        % ------------------------------------------------------------
        assert(isfield(case_item.traj, 't_s') && ~isempty(case_item.traj.t_s), ...
            'case_item.traj.t_s is missing.');
        t_s_common = case_item.traj.t_s(:);
    
        % ------------------------------------------------------------
        % Patch config with reference Walker
        % ------------------------------------------------------------
        cfg_eval = cfg;
        cfg_eval.stage03.h_km = reference_walker.h_km;
        cfg_eval.stage03.i_deg = reference_walker.i_deg;
        cfg_eval.stage03.P = reference_walker.P;
        cfg_eval.stage03.T = reference_walker.T;
        cfg_eval.stage03.F = reference_walker.F;
        cfg_eval.stage04.gamma_req = gamma_req;
    
        % ------------------------------------------------------------
        % Build / propagate constellation
        % ------------------------------------------------------------
        walker = build_single_layer_walker_stage03(cfg_eval);
        satbank = propagate_constellation_stage03(walker, t_s_common);
    
        % ------------------------------------------------------------
        % Stage03 visibility + LOS geometry
        % ------------------------------------------------------------
        vis_case = compute_visibility_matrix_stage03(case_item, satbank, cfg_eval);
        los_geom = compute_los_geometry_stage03(vis_case, satbank);
        s_vis = summarize_visibility_case_stage03(vis_case, los_geom);
    
        % ------------------------------------------------------------
        % Stage04 worst-window scan
        % ------------------------------------------------------------
        window_case = scan_worst_window_stage04(vis_case, satbank, cfg_eval);
        s_win = summarize_window_case_stage04(window_case);
    
        % ------------------------------------------------------------
        % Extract fields robustly
        % ------------------------------------------------------------
        coverage_ratio_2sat = local_try_get_struct_numeric(s_vis, 'dual_coverage_ratio', NaN);
        mean_los_intersection_angle_deg = local_try_get_struct_numeric(s_vis, 'mean_los_crossing_angle_deg', NaN);
        min_los_intersection_angle_deg = local_try_get_struct_numeric(s_vis, 'min_los_crossing_angle_deg', NaN);
    
        lambda_worst = local_try_get_struct_numeric(s_win, 'lambda_min_worst', NaN);
        t0_worst = local_try_get_struct_numeric(s_win, 't0_worst_s', NaN);
        n_visible_windows = local_try_get_struct_numeric(s_win, 'num_windows', NaN);
    
        D_G_min = NaN;
        if isfinite(lambda_worst) && isfinite(gamma_req) && gamma_req > 0
            D_G_min = lambda_worst / gamma_req;
        end
    
        % ------------------------------------------------------------
        % Build diag row
        % ------------------------------------------------------------
        case_s = case_item.case;
    
        diag_row = struct();
        diag_row.case_id = string(local_try_get_struct_string(case_s, 'case_id', ""));
        diag_row.source_case_id = string(local_try_get_struct_string(case_s, 'source_case_id', ""));
        diag_row.critical_mode = string(local_try_get_struct_string(case_s, 'critical_mode', ""));
        diag_row.critical_branch = string(local_try_get_struct_string(case_s, 'critical_branch', ""));
    
        diag_row.entry_id = local_try_get_struct_numeric(case_s, 'entry_id', NaN);
        diag_row.entry_lat_deg = local_try_get_struct_numeric(case_s, 'entry_lat_deg', NaN);
        diag_row.entry_lon_deg = local_try_get_struct_numeric(case_s, 'entry_lon_deg', NaN);
    
        diag_row.nominal_heading_deg = local_try_get_struct_numeric(case_s, 'nominal_heading_deg', NaN);
        diag_row.critical_heading_deg = local_try_get_struct_numeric(case_s, 'heading_deg', NaN);
        diag_row.heading_offset_deg = local_try_get_struct_numeric(case_s, 'heading_offset_deg', NaN);
        diag_row.heading_deg = local_try_get_struct_numeric(case_s, 'heading_deg', NaN);
    
        diag_row.h_km = reference_walker.h_km;
        diag_row.i_deg = reference_walker.i_deg;
        diag_row.P = reference_walker.P;
        diag_row.T = reference_walker.T;
        diag_row.F = reference_walker.F;
        diag_row.Ns = reference_walker.Ns;
    
        diag_row.coverage_ratio_2sat = coverage_ratio_2sat;
        diag_row.mean_los_intersection_angle_deg = mean_los_intersection_angle_deg;
        diag_row.min_los_intersection_angle_deg = min_los_intersection_angle_deg;
    
        diag_row.lambda_worst = lambda_worst;
        diag_row.D_G_min = D_G_min;
        diag_row.t0_worst = t0_worst;
        diag_row.n_visible_windows = n_visible_windows;
    
        result = struct();
        result.walker = walker;
        result.satbank = satbank;
        result.visibility_summary = s_vis;
        result.window_summary = s_win;
        result.diag_row = diag_row;
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function x = local_try_get_struct_numeric(S, field_name, fallback)
        x = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if isnumeric(val) && ~isempty(val) && isfinite(val(1))
                x = double(val(1));
            end
        end
    end
    
    function s = local_try_get_struct_string(S, field_name, fallback)
        s = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if ischar(val) || isstring(val)
                s = char(string(val));
            end
        end
    end