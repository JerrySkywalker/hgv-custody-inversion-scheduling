function fig = plot_window_family_stage04(summary_extra, cfg)
    %PLOT_WINDOW_FAMILY_STAGE04
    % Plot grouped worst-window spectrum summaries.
    
        fig = figure('Color', 'w', 'Position', [100,100,1100,420]);
    
        % ------------------------------------------------------------
        % subplot 1: family summary
        % ------------------------------------------------------------
        subplot(1,2,1); hold on; grid on;
    
        Tfam = summary_extra.family_summary;
        x = 1:height(Tfam);
    
        bar(x, Tfam.lambda_worst_mean);
        errorbar(x, Tfam.lambda_worst_mean, ...
            Tfam.lambda_worst_mean - Tfam.lambda_worst_min, ...
            Tfam.lambda_worst_max - Tfam.lambda_worst_mean, ...
            '.k', 'LineWidth', 1.2);
    
        set(gca, 'XTick', x, 'XTickLabel', cellstr(string(Tfam.group_value)));
        ylabel('lambda_worst', 'Interpreter', 'none');
        title('Stage04 family-level worst-window spectrum', 'Interpreter', 'none');
    
        % ------------------------------------------------------------
        % subplot 2: heading summary
        % ------------------------------------------------------------
        subplot(1,2,2); hold on; grid on;
    
        Thead = summary_extra.heading_summary;
        if ~isempty(Thead)
            xh = Thead.group_value;
            plot(xh, Thead.lambda_worst_mean, '-o', 'LineWidth', 1.5);
            xlabel('heading offset (deg)', 'Interpreter', 'none');
            ylabel('lambda_worst mean', 'Interpreter', 'none');
            title('Stage04 heading-offset worst-window spectrum', 'Interpreter', 'none');
        else
            text(0.5, 0.5, 'No heading summary available', ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
            axis off;
        end
    end