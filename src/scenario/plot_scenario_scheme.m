function fig = plot_scenario_scheme(cfg, casebank)
    %PLOT_SCENARIO_SCHEME Plot abstract disk-entry scenario scheme.
    
        fig = figure('Color', 'w', 'Position', [100, 100, 820, 780]);
        ax = axes(fig);
        hold(ax, 'on'); grid(ax, 'on'); axis(ax, 'equal');
    
        center_xy = casebank.disk.center_xy_km;
        R_D = casebank.disk.R_D_km;
        R_in = casebank.entry.R_in_km;
        th = linspace(0, 2*pi, 400);
    
        % Protected disk
        plot(center_xy(1) + R_D*cos(th), center_xy(2) + R_D*sin(th), ...
            'LineWidth', 2.2, ...
            'DisplayName', 'Protected disk $\Omega_D$');
    
        % Entry boundary
        plot(center_xy(1) + R_in*cos(th), center_xy(2) + R_in*sin(th), '--', ...
            'LineWidth', 1.8, ...
            'DisplayName', 'Entry boundary $\Gamma_{in}$');
    
        % Center
        scatter(center_xy(1), center_xy(2), 40, 'filled', ...
            'DisplayName', 'Protected center');
    
        % Nominal entry points + arrows
        for k = 1:numel(casebank.nominal)
            c = casebank.nominal(k);
            p = c.entry_point_xy_km;
            L = 1200;
            quiver(p(1), p(2), L*cosd(c.heading_deg), L*sind(c.heading_deg), 0, ...
                'MaxHeadSize', 0.25, 'LineWidth', 1.1, ...
                'Color', [0.2 0.4 0.9], ...
                'HandleVisibility', 'off');
        end
        scatter(casebank.entry.points_xy_km(:,1), casebank.entry.points_xy_km(:,2), ...
            18, [0.2 0.4 0.9], 'filled', ...
            'DisplayName', 'Nominal entry points');
    
        % One heading-family demo fan at first nominal point
        if ~isempty(casebank.heading)
            p_demo = casebank.heading(1).entry_point_xy_km;
            idx_demo = find(all(abs(vertcat(casebank.heading.entry_point_xy_km) - p_demo) < 1e-9, 2));
    
            for k = reshape(idx_demo, 1, [])
                c = casebank.heading(k);
                L = 1400;
                quiver(p_demo(1), p_demo(2), L*cosd(c.heading_deg), L*sind(c.heading_deg), 0, ...
                    'MaxHeadSize', 0.25, 'LineWidth', 1.0, ...
                    'Color', [0.85 0.33 0.10], ...
                    'HandleVisibility', 'off');
            end
    
            text(p_demo(1) + 180, p_demo(2) + 250, ...
                'Finite heading family (illustrative)', ...
                'Color', [0.85 0.33 0.10], ...
                'FontSize', 10, ...
                'Interpreter', 'none');
        end
    
        % Critical cases
        for k = 1:numel(casebank.critical)
            c = casebank.critical(k);
            p = c.entry_point_xy_km;
            L = 1600;
            quiver(p(1), p(2), L*cosd(c.heading_deg), L*sind(c.heading_deg), 0, ...
                'MaxHeadSize', 0.25, 'LineWidth', 1.7, ...
                'Color', [0.49 0.18 0.56], ...
                'HandleVisibility', 'off');
    
            % Use human-friendly label instead of raw ID with underscores
            label_str = local_pretty_case_label(c.subfamily);
    
            text(p(1) + 100, p(2) + 120, label_str, ...
                'Color', [0.49 0.18 0.56], ...
                'FontSize', 10, ...
                'Interpreter', 'none');
        end
    
        xlabel('Abstract regional frame x (km)', 'Interpreter', 'none');
        ylabel('Abstract regional frame y (km)', 'Interpreter', 'none');
    
        title({ ...
            'Stage01 scenario scheme', ...
            'Protected disk + entry boundary + heading family + critical families'}, ...
            'Interpreter', 'none');
    
        lgd = legend(ax, 'Location', 'northeast');
        set(lgd, 'Interpreter', 'latex');
    
        xlim(cfg.stage01.axis_limit_km * [-1, 1]);
        ylim(cfg.stage01.axis_limit_km * [-1, 1]);
    end
    
    function label_str = local_pretty_case_label(subfamily)
        switch subfamily
            case 'C1_track_plane_aligned'
                label_str = 'C1: track-plane-aligned entry';
            case 'C2_small_crossing_angle'
                label_str = 'C2: small-crossing-angle entry';
            otherwise
                label_str = subfamily;
        end
    end