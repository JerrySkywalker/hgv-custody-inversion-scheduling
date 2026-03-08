function fig = plot_hgv_casebank_stage02(cfg, trajbank)
    %PLOT_HGV_CASEBANK_STAGE02
    % Plot representative Stage02 trajectories in a cleaner, case-aligned way.
    %
    % Stage04G.4a:
    %   - show one representative entry-angle family explicitly
    %   - avoid misleading overplotting in geodetic mode
    
        target_theta = local_get_cfg(cfg.stage02, 'example_entry_theta_deg', 0);
        offsets_to_show = local_get_cfg(cfg.stage02, 'example_show_heading_offsets', [0, -30, 30, -60, 60]);
        include_critical = local_get_cfg(cfg.stage02, 'example_include_critical', true);
    
        fig = figure('Color', 'w', 'Position', [80, 80, 1280, 520]);
    
        % ------------------------------------------------------------
        % Left panel: representative ENU xy trajectories
        % ------------------------------------------------------------
        ax1 = subplot(1,2,1);
        hold(ax1, 'on'); grid(ax1, 'on'); axis(ax1, 'equal');
    
        th = linspace(0, 2*pi, 400);
        plot(ax1, cfg.stage01.R_D_km*cos(th), cfg.stage01.R_D_km*sin(th), ...
            'LineWidth', 2.0, 'DisplayName', 'Protected disk');
    
        % nominal
        idx_nom = local_find_nominal_by_theta(trajbank.nominal, target_theta);
        if ~isempty(idx_nom)
            tr = trajbank.nominal(idx_nom).traj;
            plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), 'LineWidth', 2.0, ...
                'DisplayName', 'Nominal');
        end
    
        % heading offsets at same entry point
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = trajbank.heading(idx_h).traj;
            plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), 'LineWidth', 1.5, ...
                'DisplayName', pretty_label_stage02('heading', offsets_to_show(k)));
        end
    
        % critical
        if include_critical
            for k = 1:numel(trajbank.critical)
                tr = trajbank.critical(k).traj;
                c = trajbank.critical(k).case;
                plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), '--', 'LineWidth', 1.8, ...
                    'DisplayName', pretty_label_stage02('critical', c.subfamily));
            end
        end
    
        xlabel(ax1, 'x (km)', 'Interpreter', 'none');
        ylabel(ax1, 'y (km)', 'Interpreter', 'none');
        title(ax1, 'Stage02 representative ENU trajectories', 'Interpreter', 'none');
        legend(ax1, 'Location', 'best', 'Interpreter', 'none');
    
        % ------------------------------------------------------------
        % Right panel: representative altitude histories
        % ------------------------------------------------------------
        ax2 = subplot(1,2,2);
        hold(ax2, 'on'); grid(ax2, 'on');
    
        if ~isempty(idx_nom)
            tr = trajbank.nominal(idx_nom).traj;
            plot(ax2, tr.t_s, tr.h_km, 'LineWidth', 2.0, 'DisplayName', 'Nominal');
        end
    
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = trajbank.heading(idx_h).traj;
            plot(ax2, tr.t_s, tr.h_km, 'LineWidth', 1.5, ...
                'DisplayName', pretty_label_stage02('heading', offsets_to_show(k)));
        end
    
        if include_critical
            for k = 1:numel(trajbank.critical)
                tr = trajbank.critical(k).traj;
                c = trajbank.critical(k).case;
                plot(ax2, tr.t_s, tr.h_km, '--', 'LineWidth', 1.8, ...
                    'DisplayName', pretty_label_stage02('critical', c.subfamily));
            end
        end
    
        xlabel(ax2, 'time (s)', 'Interpreter', 'none');
        ylabel(ax2, 'altitude (km)', 'Interpreter', 'none');
        title(ax2, 'Stage02 representative altitude histories', 'Interpreter', 'none');
    end
    
    function idx = local_find_nominal_by_theta(family_struct, target_theta)
        idx = [];
        for i = 1:numel(family_struct)
            c = family_struct(i).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6
                idx = i;
                return;
            end
        end
    end
    
    function idx = local_find_heading_by_theta_offset(family_struct, target_theta, target_offset)
        idx = [];
        for i = 1:numel(family_struct)
            c = family_struct(i).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6 && ...
               isfield(c, 'heading_offset_deg') && isfinite(c.heading_offset_deg) && ...
               abs(c.heading_offset_deg - target_offset) < 1e-6
                idx = i;
                return;
            end
        end
    end
    
    function v = local_get_cfg(s, name, defaultv)
        if isstruct(s) && isfield(s, name)
            v = s.(name);
        else
            v = defaultv;
        end
    end