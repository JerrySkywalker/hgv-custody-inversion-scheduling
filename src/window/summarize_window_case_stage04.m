function s = summarize_window_case_stage04(window_case)
    %SUMMARIZE_WINDOW_CASE_STAGE04 Per-case window summary.
    
        s = struct();
        s.case_id = window_case.case_id;
        s.family = window_case.family;
        s.subfamily = window_case.subfamily;
    
        s.num_windows = window_case.window_grid.num_windows;
        s.lambda_min_worst = window_case.lambda_min_worst;
        s.lambda_min_best = max(window_case.lambda_min);
        s.lambda_min_mean = mean(window_case.lambda_min, 'omitnan');
        s.t0_worst_s = window_case.t0_worst_s;
    end