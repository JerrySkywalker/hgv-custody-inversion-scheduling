function fig = plot_hgv_entrypoint_3d_stage02(cfg, trajbank)
    %PLOT_HGV_ENTRYPOINT_3D_STAGE02
    % Plot representative 3D trajectories for one chosen entry angle.
    %
    % Stage04G.4a:
    %   - explicitly compare nominal vs heading offsets
    %   - avoid misleading bulk plotting
    
        target_theta = local_get_cfg(cfg.stage02, 'example_entry_theta_deg', 0);
        offsets_to_show = local_get_cfg(cfg.stage02, 'example_show_heading_offsets', [0, -30, 30, -60, 60]);
        include_critical = local_get_cfg(cfg.stage02, 'example_include_critical', true);
    
        fig = figure('Color', 'w', 'Position', [100, 100, 980, 760]);
        ax = axes(fig);
        hold(ax, 'on'); grid(ax, 'on'); view(ax, 3);
    
        % protected disk footprint on z = 0 plane
        th = linspace(0, 2*pi, 400);
        xD = cfg.stage01.R_D_km * cos(th);
        yD = cfg.stage01.R_D_km * sin(th);
        zD = zeros(size(th));
        plot3(ax, xD, yD, zD, 'LineWidth', 2.0, 'DisplayName', 'Protected disk footprint');
    
        % nominal
        idx_nom = local_find_nominal_by_theta(trajbank.nominal, target_theta);
        if ~isempty(idx_nom)
            tr = trajbank.nominal(idx_nom).traj;
            plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                'LineWidth', 2.0, 'DisplayName', 'Nominal');
        end
    
        % heading family
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = trajbank.heading(idx_h).traj;
            plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                'LineWidth', 1.5, ...
                'DisplayName', pretty_label_stage02('heading', offsets_to_show(k)));
        end
    
        % critical
        if include_critical
            for k = 1:numel(trajbank.critical)
                tr = trajbank.critical(k).traj;
                c = trajbank.critical(k).case;
                plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, '--', ...
                    'LineWidth', 1.8, ...
                    'DisplayName', pretty_label_stage02('critical', c.subfamily));
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