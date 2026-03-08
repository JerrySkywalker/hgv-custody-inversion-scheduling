function fig = plot_window_margin_stage04(summary_margin, cfg)
    %PLOT_WINDOW_MARGIN_STAGE04
    % Plot D_G summaries for Stage04.2
    
        fig = figure('Color', 'w', 'Position', [100,100,1100,420]);
    
        % ------------------------------------------------------------
        % subplot 1: family D_G
        % ------------------------------------------------------------
        subplot(1,2,1); hold on; grid on;
    
        Tfam = summary_margin.family_summary;
        x = 1:height(Tfam);
    
        bar(x, Tfam.D_G_mean);
        yline(1, '--');
        errorbar(x, Tfam.D_G_mean, ...
            Tfam.D_G_mean - Tfam.D_G_min, ...
            Tfam.D_G_max - Tfam.D_G_mean, ...
            '.k', 'LineWidth', 1.2);
    
        set(gca, 'XTick', x, 'XTickLabel', cellstr(string(Tfam.group_value)));
        ylabel('D_G', 'Interpreter', 'none');
        title('Stage04.2 family-level margin', 'Interpreter', 'none');
    
        % ------------------------------------------------------------
        % subplot 2: heading D_G
        % ------------------------------------------------------------
        subplot(1,2,2); hold on; grid on;
    
        Thead = summary_margin.heading_summary;
        if ~isempty(Thead)
            plot(Thead.group_value, Thead.D_G_mean, '-o', 'LineWidth', 1.5);
            yline(1, '--');
            xlabel('heading offset (deg)', 'Interpreter', 'none');
            ylabel('D_G mean', 'Interpreter', 'none');
            title('Stage04.2 heading-offset margin', 'Interpreter', 'none');
        else
            text(0.5, 0.5, 'No heading summary available', ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
            axis off;
        end
    end