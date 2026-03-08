function fig = plot_visibility_case_stage03(visbank, case_id, cfg)
    %PLOT_VISIBILITY_CASE_STAGE03
    % Plot one representative visibility case.
    %
    % Stage04G.5:
    %   - use ECI-based visibility results already stored in vis_case
    %   - left: visible satellite count
    %   - right: best LOS crossing angle over visible pairs
    
        vis_case = local_find_case(visbank, case_id);
        assert(~isempty(vis_case), 'Case %s not found in visbank.', case_id);
    
        t_s = vis_case.t_s;
        num_visible = vis_case.num_visible;
        best_crossing_deg = vis_case.best_crossing_deg;
    
        fig = figure('Color', 'w', 'Position', [100, 100, 1120, 480]);
    
        ax1 = subplot(1,2,1);
        hold(ax1, 'on'); grid(ax1, 'on');
        plot(ax1, t_s, num_visible, 'LineWidth', 2.0);
        yline(ax1, 2, '--', 'LineWidth', 1.2);
        xlabel(ax1, 'time (s)', 'Interpreter', 'none');
        ylabel(ax1, 'num visible satellites', 'Interpreter', 'none');
        title(ax1, sprintf('Visibility count: %s', case_id), 'Interpreter', 'none');
    
        ax2 = subplot(1,2,2);
        hold(ax2, 'on'); grid(ax2, 'on');
        plot(ax2, t_s, best_crossing_deg, 'LineWidth', 2.0);
        xlabel(ax2, 'time (s)', 'Interpreter', 'none');
        ylabel(ax2, 'best LOS crossing angle (deg)', 'Interpreter', 'none');
        title(ax2, sprintf('LOS geometry: %s', case_id), 'Interpreter', 'none');
    end
    
    function vis_case = local_find_case(visbank, case_id)
        vis_case = [];
    
        family_names = fieldnames(visbank);
        for f = 1:numel(family_names)
            family = visbank.(family_names{f});
            for i = 1:numel(family)
                if strcmp(family(i).case.case_id, case_id)
                    vis_case = family(i).vis;
                    return;
                end
            end
        end
    end