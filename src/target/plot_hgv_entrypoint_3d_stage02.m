function fig = plot_hgv_entrypoint_3d_stage02(cfg, trajbank)
    %PLOT_HGV_ENTRYPOINT_3D_STAGE02
    % Plot (x,y,h) trajectories for one representative entry angle.
    
        target_theta = cfg.stage02.example_entry_theta_deg;
        offsets_to_show = cfg.stage02.example_show_heading_offsets;
    
        fig = figure('Color', 'w', 'Position', [100, 100, 920, 720]);
        ax = axes(fig);
        hold(ax, 'on'); grid(ax, 'on'); view(ax, 3);
    
        % ------------------------------------------------------------
        % Protected disk footprint on z = 0 plane
        % ------------------------------------------------------------
        th = linspace(0, 2*pi, 400);
        xD = cfg.stage01.R_D_km * cos(th);
        yD = cfg.stage01.R_D_km * sin(th);
        zD = zeros(size(th));
        plot3(ax, xD, yD, zD, 'LineWidth', 2.0, 'DisplayName', 'Protected disk footprint');
    
        % ------------------------------------------------------------
        % Plot nominal trajectory at chosen entry angle
        % ------------------------------------------------------------
        for k = 1:numel(trajbank.nominal)
            c = trajbank.nominal(k).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6
                xy = trajbank.nominal(k).traj.xy_km;
                h = trajbank.nominal(k).traj.h_km;
                plot3(ax, xy(:,1), xy(:,2), h, 'LineWidth', 2.0, 'DisplayName', 'Nominal');
            end
        end
    
        % ------------------------------------------------------------
        % Plot heading-family trajectories at same entry angle
        % ------------------------------------------------------------
        for k = 1:numel(trajbank.heading)
            c = trajbank.heading(k).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6 && ...
               any(abs(c.heading_offset_deg - offsets_to_show) < 1e-6)
    
                xy = trajbank.heading(k).traj.xy_km;
                h = trajbank.heading(k).traj.h_km;
                label_str = pretty_label_stage02('heading', c.heading_offset_deg);
    
                plot3(ax, xy(:,1), xy(:,2), h, 'LineWidth', 1.4, 'DisplayName', label_str);
            end
        end
    
        % ------------------------------------------------------------
        % Optionally overlay critical trajectories
        % ------------------------------------------------------------
        if cfg.stage02.example_include_critical
            for k = 1:numel(trajbank.critical)
                c = trajbank.critical(k).case;
                xy = trajbank.critical(k).traj.xy_km;
                h = trajbank.critical(k).traj.h_km;
                label_str = pretty_label_stage02('critical', c.subfamily);
    
                plot3(ax, xy(:,1), xy(:,2), h, '--', 'LineWidth', 1.8, 'DisplayName', label_str);
            end
        end
    
        xlabel(ax, 'x (km)', 'Interpreter', 'none');
        ylabel(ax, 'y (km)', 'Interpreter', 'none');
        zlabel(ax, 'altitude (km)', 'Interpreter', 'none');
    
        title(ax, sprintf('Stage02 3D trajectories at entry angle %g deg', target_theta), ...
            'Interpreter', 'none');
    
        legend(ax, 'Location', 'best', 'Interpreter', 'none');
    
        axis(ax, 'tight');
    end
    
    function s = local_pretty_critical_label(subfamily)
        switch subfamily
            case 'C1_track_plane_aligned'
                s = 'C1: track-plane-aligned';
            case 'C2_small_crossing_angle'
                s = 'C2: small-crossing-angle';
            otherwise
                s = char(string(subfamily));
        end
    end