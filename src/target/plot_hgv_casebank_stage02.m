function fig = plot_hgv_casebank_stage02(cfg, trajbank)
    %PLOT_HGV_CASEBANK_STAGE02 Plot representative Stage02 trajectories.
    
        fig = figure('Color', 'w', 'Position', [80, 80, 1200, 500]);
    
        % ---------------------------
        % left: xy trajectories
        % ---------------------------
        subplot(1,2,1); hold on; grid on; axis equal;
    
        th = linspace(0, 2*pi, 400);
        plot(cfg.stage01.R_D_km*cos(th), cfg.stage01.R_D_km*sin(th), 'LineWidth', 2);
    
        local_plot_family_xy(trajbank.nominal, cfg.stage02.plot_num_cases_each_family);
        local_plot_family_xy(trajbank.heading, cfg.stage02.plot_num_cases_each_family);
        local_plot_family_xy(trajbank.critical, cfg.stage02.plot_num_cases_each_family);
    
        xlabel('x (km)', 'Interpreter', 'none');
        ylabel('y (km)', 'Interpreter', 'none');
        title('Stage02 representative xy trajectories', 'Interpreter', 'none');
    
        % ---------------------------
        % right: altitude histories
        % ---------------------------
        subplot(1,2,2); hold on; grid on;
    
        local_plot_family_h(trajbank.nominal, cfg.stage02.plot_num_cases_each_family);
        local_plot_family_h(trajbank.heading, cfg.stage02.plot_num_cases_each_family);
        local_plot_family_h(trajbank.critical, cfg.stage02.plot_num_cases_each_family);
    
        xlabel('time (s)', 'Interpreter', 'none');
        ylabel('altitude (km)', 'Interpreter', 'none');
        title('Stage02 representative altitude histories', 'Interpreter', 'none');
    end
    
    function local_plot_family_xy(trajs, n_show)
        if isempty(trajs), return; end
        n = min(numel(trajs), n_show);
        idx = round(linspace(1, numel(trajs), n));
        for i = idx
            xy = trajs(i).traj.xy_km;
            plot(xy(:,1), xy(:,2), 'LineWidth', 1.0);
        end
    end
    
    function local_plot_family_h(trajs, n_show)
        if isempty(trajs), return; end
        n = min(numel(trajs), n_show);
        idx = round(linspace(1, numel(trajs), n));
        for i = idx
            t = trajs(i).traj.t_s;
            h = trajs(i).traj.h_km;
            plot(t, h, 'LineWidth', 1.0);
        end
    end