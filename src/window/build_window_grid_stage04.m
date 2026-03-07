function window_grid = build_window_grid_stage04(t_s, cfg)
    %BUILD_WINDOW_GRID_STAGE04 Build sliding-window start indices.
    
        Tw_s = cfg.stage04.Tw_s;
        step_s = cfg.stage04.window_step_s;
    
        dt = median(diff(t_s));
        win_len = max(1, round(Tw_s / dt));
        step_len = max(1, round(step_s / dt));
    
        Nt = numel(t_s);
    
        start_idx = 1:step_len:(Nt - win_len + 1);
        end_idx = start_idx + win_len - 1;
    
        window_grid = struct();
        window_grid.start_idx = start_idx(:);
        window_grid.end_idx = end_idx(:);
        window_grid.num_windows = numel(start_idx);
        window_grid.win_len = win_len;
        window_grid.dt = dt;
    end