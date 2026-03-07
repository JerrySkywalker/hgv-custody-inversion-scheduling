function fig = plot_visibility_case_stage03(vis_case, los_geom, cfg)
    %PLOT_VISIBILITY_CASE_STAGE03 Plot one example case visibility timeline.
    
        fig = figure('Color', 'w', 'Position', [100,100,1000,420]);
    
        subplot(1,2,1); hold on; grid on;
        plot(vis_case.t_s, vis_case.num_visible, 'LineWidth', 1.5);
        yline(2, '--');
        xlabel('time (s)', 'Interpreter', 'none');
        ylabel('num visible satellites', 'Interpreter', 'none');
        title(sprintf('Visibility count: %s', vis_case.case_id), 'Interpreter', 'none');
    
        subplot(1,2,2); hold on; grid on;
        plot(vis_case.t_s, los_geom.min_crossing_angle_deg, 'LineWidth', 1.5);
        xlabel('time (s)', 'Interpreter', 'none');
        ylabel('min LOS crossing angle (deg)', 'Interpreter', 'none');
        title(sprintf('LOS geometry: %s', vis_case.case_id), 'Interpreter', 'none');
    end