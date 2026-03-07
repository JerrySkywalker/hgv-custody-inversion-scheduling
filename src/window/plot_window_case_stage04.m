function fig = plot_window_case_stage04(window_case, cfg)
    %PLOT_WINDOW_CASE_STAGE04 Plot lambda_min(Wr) over sliding windows.
    
        fig = figure('Color', 'w', 'Position', [100,100,900,420]);
    
        t0_s = window_case.window_grid.start_idx * window_case.window_grid.dt;
    
        plot(t0_s, window_case.lambda_min, 'LineWidth', 1.5);
        hold on; grid on;
    
        xline(window_case.t0_worst_s, '--');
        xlabel('window start time t_0 (s)', 'Interpreter', 'none');
        ylabel('lambda_min(W_r)', 'Interpreter', 'none');
        title(sprintf('Stage04 worst-window scan: %s', window_case.case_id), 'Interpreter', 'none');
    end