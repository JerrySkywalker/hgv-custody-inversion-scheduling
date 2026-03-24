function fig = plot_window_family_stage04(summary_spectrum, cfg)
    %PLOT_WINDOW_FAMILY_STAGE04
    % Thesis-friendly Stage04 spectrum visualization.
    %
    % New design:
    %   left  : family-level lambda_worst scatter + median line (log y-scale)
    %   right : heading-offset lambda_worst scatter + median point/line (log y-scale)
    %
    % Zero values are clipped to a small display floor for log-scale rendering.
    % The actual statistics are NOT modified; clipping is only for visualization.
    
        T = summary_spectrum.case_table;
    
        fig = figure('Color', 'w', 'Position', [100,100,1180,440]);
    
        % Display floor for zeros on log axis
        y_floor = 1e-3;
    
        % ============================================================
        % subplot 1: family-level distribution
        % ============================================================
        subplot(1,2,1); hold on; grid on;
    
        family_order = ["nominal","heading","critical"];
        x_family = 1:numel(family_order);
    
        for i = 1:numel(family_order)
            fam = family_order(i);
            idx = strcmp(string(T.families), fam);
            y_raw = T.lambda_worst(idx);
    
            if isempty(y_raw)
                continue;
            end
    
            % for display only: clip zeros to floor
            y_plot = max(y_raw, y_floor);
    
            % deterministic jitter
            if numel(y_plot) == 1
                jitter = 0;
            else
                jitter = linspace(-0.12, 0.12, numel(y_plot)).';
            end
            xj = x_family(i) + jitter;
    
            scatter(xj, y_plot, 28, 'filled', ...
                'MarkerFaceAlpha', 0.68, ...
                'MarkerEdgeAlpha', 0.68);
    
            % median line (use displayed median with same clipping)
            y_med = median(y_raw, 'omitnan');
            y_med_plot = max(y_med, y_floor);
            plot([x_family(i)-0.22, x_family(i)+0.22], [y_med_plot, y_med_plot], ...
                'k-', 'LineWidth', 2.0);
        end
    
        set(gca, 'XTick', x_family, 'XTickLabel', cellstr(family_order));
        set(gca, 'YScale', 'log');
        ylabel('lambda\_worst', 'Interpreter', 'tex');
        title('Stage04 family-level worst-window spectrum', 'Interpreter', 'none');
    
        % add a note for clipped zeros
        text(0.02, 0.03, sprintf('Display floor for zero values: %.0e', y_floor), ...
            'Units', 'normalized', 'Interpreter', 'none', 'FontSize', 9);
    
        % ============================================================
        % subplot 2: heading-offset distribution
        % ============================================================
        subplot(1,2,2); hold on; grid on;
    
        idx_heading = strcmp(string(T.families), "heading");
        Th = T(idx_heading, :);
    
        if isempty(Th)
            text(0.5, 0.5, 'No heading cases available', ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
            axis off;
            return;
        end
    
        offsets = unique(Th.heading_offsets);
        offsets = offsets(~isnan(offsets));
        offsets = sort(offsets(:));
    
        for i = 1:numel(offsets)
            h = offsets(i);
            idx = (Th.heading_offsets == h);
            y_raw = Th.lambda_worst(idx);
    
            if isempty(y_raw)
                continue;
            end
    
            y_plot = max(y_raw, y_floor);
    
            % deterministic jitter around discrete heading offset
            if numel(y_plot) == 1
                jitter = 0;
            else
                jitter = linspace(-2.0, 2.0, numel(y_plot)).';
            end
            xj = h + jitter;
    
            scatter(xj, y_plot, 28, 'filled', ...
                'MarkerFaceAlpha', 0.68, ...
                'MarkerEdgeAlpha', 0.68);
    
            % median point + short horizontal line
            y_med = median(y_raw, 'omitnan');
            y_med_plot = max(y_med, y_floor);
            plot(h, y_med_plot, 'ko', 'MarkerSize', 7, 'LineWidth', 1.5);
            plot([h-3.0, h+3.0], [y_med_plot, y_med_plot], 'k-', 'LineWidth', 1.8);
        end
    
        set(gca, 'YScale', 'log');
        xlabel('heading offset (deg)', 'Interpreter', 'none');
        ylabel('lambda\_worst', 'Interpreter', 'tex');
        title('Stage04 heading-offset worst-window spectrum', 'Interpreter', 'none');
        xlim([min(offsets)-8, max(offsets)+8]);
    
        text(0.02, 0.03, sprintf('Display floor for zero values: %.0e', y_floor), ...
            'Units', 'normalized', 'Interpreter', 'none', 'FontSize', 9);
    end