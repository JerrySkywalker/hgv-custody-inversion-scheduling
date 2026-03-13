function window_case = scan_worst_window_stage04(vis_case, satbank, cfg)
    %SCAN_WORST_WINDOW_STAGE04
    % Scan all windows and compute lambda_min(Wr).
    %
    % Stage04G.6:
    %   - assumes vis_case.r_tgt_eci_km is the true target ECI trajectory
    %   - stores geometry metadata
    %   - uses exact t0 from window_grid.t0_s
    
        t_s = vis_case.t_s;
        window_grid = build_window_grid_stage04(t_s, cfg);
        Wr_t = build_time_info_series_stage04(vis_case, satbank, cfg);
        Wr_prefix = [zeros(1, 9); cumsum(reshape(Wr_t, size(Wr_t, 1), 9), 1)];
    
        nW = window_grid.num_windows;
        lambda_min = nan(nW,1);
        trace_Wr = nan(nW,1);
    
        for w = 1:nW
            i0 = window_grid.start_idx(w);
            i1 = window_grid.end_idx(w);
    
            Wr = reshape(Wr_prefix(i1 + 1, :) - Wr_prefix(i0, :), 3, 3);
            Wr = 0.5 * (Wr + Wr.');  % enforce symmetry
    
            ev = eig(Wr);
            ev = sort(real(ev), 'ascend');
    
            lambda_min(w) = max(ev(1), 0);
            trace_Wr(w) = trace(Wr);
        end
    
        [lambda_min_worst, idx_worst] = min(lambda_min);
    
        window_case = struct();
        window_case.case_id = vis_case.case_id;
        window_case.family = vis_case.family;
        window_case.subfamily = vis_case.subfamily;
    
        window_case.window_grid = window_grid;
        window_case.lambda_min = lambda_min;
        window_case.trace_Wr = trace_Wr;
        window_case.idx_worst = idx_worst;
    
        window_case.lambda_min_worst = lambda_min_worst;
        window_case.t0_worst_s = window_grid.t0_s(idx_worst);
    
        window_case.meta = struct();
        if isfield(vis_case, 'r_tgt_eci_km')
            window_case.meta.geometry_mode = 'ECI';
            window_case.meta.Nt = size(vis_case.r_tgt_eci_km, 1);
        else
            window_case.meta.geometry_mode = 'unknown';
            window_case.meta.Nt = numel(t_s);
        end
    end
