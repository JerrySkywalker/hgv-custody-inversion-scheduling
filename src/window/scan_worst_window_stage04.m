function window_case = scan_worst_window_stage04(vis_case, satbank, cfg)
    %SCAN_WORST_WINDOW_STAGE04
    % Scan all windows and compute lambda_min(Wr).
    
        t_s = vis_case.t_s;
        window_grid = build_window_grid_stage04(t_s, cfg);
    
        nW = window_grid.num_windows;
        lambda_min = nan(nW,1);
        trace_Wr = nan(nW,1);
    
        for w = 1:nW
            i0 = window_grid.start_idx(w);
            i1 = window_grid.end_idx(w);
    
            Wr = build_window_info_matrix_stage04(vis_case, i0, i1, satbank, cfg);
            Wr = 0.5 * (Wr + Wr.');  % enforce symmetry
    
            ev = eig(Wr);
            ev = sort(real(ev), 'ascend');
    
            % lambda_min(w) = ev(1);
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
        window_case.t0_worst_s = t_s(window_grid.start_idx(idx_worst));
    end